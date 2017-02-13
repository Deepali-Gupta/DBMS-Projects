--1--
--PREAMBLE--
create view v1 as
	select coachid, cast(sum(won) as real)/cast(sum(won+lost) as real) as percent
	from basketball_coaches
	where won is not null or lost is not null
	group by coachid;
create view v2 as
	select max(percent) as maxpercent
	from v1;
--QUERY--
select coachid
from v1,v2
where v1.percent = v2.maxpercent
order by coachid;
--CLEANUP--
drop view v1,v2;

--2--
--QUERY--
select coachid, coalesce(cast(sum(won) as real)/cast(sum(won+lost) as real),0) as successrate
from basketball_coaches
group by coachid
order by successrate desc, coachid;

--3--
--QUERY--
select tmid, year
from basketball_team
where rank=1
order by tmid, year;

--4--
--PREAMBLE--
create view v1 as
	select year, count(*) as nummatches
	from basketball_series
	group by year;
create view v2 as
	select max(nummatches) as numofmatches
	from v1;
--QUERY--
select year, nummatches
from v1, v2
where v1.nummatches=v2.numofmatches
order by nummatches, year;
--CLEANUP--
drop view v1, v2;

--5--
--PREAMBLE--
create view v as
	select distinct on (tmid, playerid, ratio) basketball_team.tmid, playerid, (cast(points as real)/cast(gp as numeric)) as ratio
	from basketball_team inner join basketball_player
	on basketball_team.tmid=basketball_player.tmid
	where gp<>0
	order by tmid, ratio desc, playerid;
--QUERY--
select sub2.tmid, playerid
from v inner join (
		select tmid, max(ratio) as maxratio
		from v
		group by tmid
		order by tmid, maxratio desc
	 ) sub2 on v.ratio=sub2.maxratio
where v.tmid=sub2.tmid
order by sub2.tmid, playerid;
--CLEANUP--
drop view v;

--6--
--PREAMBLE--
create view v1 as
	select tmidwinner as tmid, count(*) as wintimes
	from basketball_series
	where round = (
					select distinct on(code) code
					from basketball_abbrev
					where full_name = 'Semifinals'
				  )
	or round = (
					select distinct on(code) code
					from basketball_abbrev
					where full_name = 'Finals'
				  )
	group by tmidwinner
	order by tmidwinner;
create view v2 as
	select tmidloser as tmid, count(*) as losetimes
	from basketball_series
	where round = (
					select distinct on(code) code
					from basketball_abbrev
					where full_name = 'Semifinals'
				  )
	or round = (
					select distinct on(code) code
					from basketball_abbrev
					where full_name = 'Finals'
				  )
	group by tmidloser
	order by tmidloser;
create view v3 as
	select max(wintimes+losetimes) as count
	from v1 inner join v2
	on v1.tmid=v2.tmid
	order by count desc;
--QUERY--
select sub1.tmid as tmid, sub1.count as count
from (select v1.tmid as tmid, (wintimes+losetimes) as count from v1 inner join v2
on v1.tmid=v2.tmid ) sub1 inner join v3 on sub1.count=v3.count
order by tmid, count;
--CLEANUP--
drop view v1,v2,v3;

--7--
--PREAMBLE--
create view v as
	select basketball_team.year, basketball_team.tmid
	from basketball_series inner join basketball_team
	on basketball_series.tmidwinner=basketball_team.tmid
	or basketball_series.tmidloser=basketball_team.tmid
	where basketball_series.year=basketball_team.year
	and (basketball_series.year='1946'
	or basketball_series.year='1947'
	or basketball_series.year='1948')
	and basketball_series.round = (select code from basketball_abbrev where full_name = 'Finals');
--QUERY--
select v.tmid, playerid
from v inner join basketball_player
on v.tmid=basketball_player.tmid
order by tmid, playerid;
--CLEANUP--
drop view v;

--8--
--QUERY--
select playerid
from basketball_master as t1 inner join basketball_player as t2
on t1.bioid = t2.playerid
where t1.college='Duke'
and t2.tmid='NYK'
order by playerid;

--9--
--PREAMBLE--
create view v as
	select coachid, t1.tmid, t1.year
	from basketball_coaches as t1 inner join basketball_team as t2
	on t1.tmid=t2.tmid
	and t1.year=t2.year;
--QUERY--
select playerid
from basketball_player as t inner join v
on t.tmid=v.tmid
and t.year=v.year
where v.coachid='olsenha01'
order by playerid;
--CLEANUP--
drop view v;

--10--
--QUERY--
select playerid
from (
select playerid, sum(fgmade) as goals
from basketball_player
group by playerid
) sub
where goals<=500 and goals>=200
order by playerid;

--11--
--PREAMBLE--
create view v1 as
	select playerid, tmid
	from basketball_master as t1 inner join basketball_player as t2
	on t1.bioid=t2.playerid
	where t1.firstname='mark' or t1.firstname='Mark';
create view v2 as
	select v1.tmid, coachid
	from v1 inner join basketball_coaches as t
	on v1.tmid = t.tmid;
--QUERY--
select tmid, firstname as coachname
from v2 inner join basketball_master as m
on v2.coachid=m.bioid
order by coachname, tmid;
--CLEANUP--
drop view v1,v2;

--12--
--PREAMBLE--
create view v1 as
	select playerid, extract('year' from birthdate) as birthyear
	from basketball_master as t1 inner join basketball_player as t2
	on t1.bioid=t2.playerid
	where t1.birthcity='Detroit'
	and t1.race='W';
--QUERY--
select firstname
from basketball_master as t1 inner join v1
on extract('year' from birthdate)=v1.birthyear
order by firstname desc;
--CLEANUP--
drop view v1;

--13--
--PREAMBLE--
create view v1 as
	select playerid, t1.tmid, sum(points) as totalpoints
	from basketball_team as t1 inner join basketball_player as t2
	on t1.tmid=t2.tmid
	and t1.year=t2.year
	where divid=(
					select code
					from basketball_abbrev
					where full_name='West Division'
				)
	group by playerid, t1.tmid;
--QUERY--
select firstname, playerid, totalpoints
from basketball_master as t1 inner join v1
on t1.bioid=v1.playerid
where totalpoints>=700
order by firstname, playerid, totalpoints;
--CLEANUP--
drop view v1;

--14--
--PREAMBLE--
create view y as
	select tmidloser
	from basketball_series
	where w-l>=2;
create view ratios as
	select tmid, divid, (cast(sum(won) as real)/cast(sum(lost) as real)) as ratio
	from basketball_team
	where lost<>0
	group by tmid, divid;
create view divids as
	select distinct on(divid) divid
	from y inner join ratios
	on y.tmidloser=ratios.tmid;
--QUERY--
select full_name as division, count
from basketball_abbrev inner join 
	(select divids.divid, coalesce(count(ratios.divid),0) as count
	from divids left outer join ratios
	on divids.divid=ratios.divid
	and ratio > (select max(ratio)
						from y inner join ratios
						on y.tmidloser=ratios.tmid)
	where divids.divid is not null
	group by divids.divid
	) sub3 on basketball_abbrev.code=sub3.divid
order by division, count;
--CLEANUP--
drop view y,ratios,divids;
