--1--
--QUERY--
select housename, count(distinct devicetype) as num_devicetypes
from house left outer join appliance
on house.houseid=appliance.houseid
group by house.houseid
order by housename;

--2--
--QUERY--
select housename, appname, devicetype
from house inner join appliance
on house.houseid=appliance.houseid
order by housename, appname;

--3--
--QUERY--
select appname, round(cast(avg(power) as numeric),2) as avgpower
from appliance inner join plugdata
on appliance.applianceid=plugdata.applianceid
where appliance.houseid = (select houseid
						   from house
						   where housename='House2')
and power<>-1
group by appliance.applianceid
order by appname;

--4--
--QUERY--
select appname, round(cast(max(power) as numeric),2) as maxpower, round(cast(min(power) as numeric),2) as minpower, round(cast(avg(power) as numeric),2) as avgpower
from appliance inner join plugdata
on appliance.applianceid=plugdata.applianceid
where appliance.houseid = (select houseid
						   from house
						   where housename='House4')
and power<>-1
group by appliance.applianceid
order by appname;

--5--
--PREAMBLE--
create view v1 as
	select houseid, appliance.applianceid, devicetype, sum(power) as totalpower
	from appliance inner join plugdata
	on appliance.applianceid=plugdata.applianceid
	where power<>-1
	group by houseid, appliance.applianceid, devicetype;
create view v2 as 
	select devicetype, housename, totalpower
	from house inner join v1
	on house.houseid=v1.houseid
	order by devicetype, totalpower desc, housename asc;
--QUERY--
select distinct on (devicetype) devicetype, housename
from v2;
--CLEANUP--
drop view v1, v2;

--6--
--QUERY--
select devicetype, round(cast(avg(power) as numeric),2) as avgpower
from appliance inner join plugdata
on appliance.applianceid=plugdata.applianceid
where power<>-1
group by devicetype
order by devicetype;

--7--
--QUERY--
select housename, avgappliancepower, avgallpower
from house inner join 
				(select sub1.houseid, avgappliancepower, avgallpower 
					from 
						(select houseid, round(cast(avg(power) as numeric),2) as avgappliancepower
						from appliance inner join plugdata
						on appliance.applianceid=plugdata.applianceid
						where power<>-1
						group by houseid
						) sub1 
					inner join
						(select houseid, round(cast(avg(powerallphases) as numeric),2) as avgallpower
						from smartmeterdata
						where powerallphases<>-1
						group by houseid
						) sub2 
					on sub1.houseid=sub2.houseid
				) sub 
		on house.houseid=sub.houseid
order by housename;

--8--
--QUERY--
select extract('hour' from readingtime) as hour, round(cast(min(powerallphases) as numeric),2) as minpower, round(cast(max(powerallphases) as numeric),2) as maxpower, round(cast(avg(powerallphases) as numeric),2) as avgpower
from smartmeterdata
where powerallphases<>-1
and houseid = (select houseid
			   from house
			   where housename='House1')
group by houseid, hour
order by hour;

--9--
--PREAMBLE--
create view v as
	select row_number() over(order by housename, applianceid, readingtime) as id, housename, applianceid, readingtime, power
	from house inner join (
							select houseid,appliance.applianceid, readingtime, power
							from appliance inner join plugdata
							on appliance.applianceid=plugdata.applianceid
							where power=0
						  ) sub1
	on house.houseid=sub1.houseid
	order by housename, applianceid, readingtime;
create view timediff as
	select t1.housename, t1.applianceid, 60*date_part('hour', t2.readingtime-t1.readingtime)+date_part('minute', t2.readingtime-t1.readingtime) as diff
	from v as t1 inner join v as t2
	on t1.applianceid=t2.applianceid
	and extract('day' from t1.readingtime)=extract('day' from t2.readingtime)
	and t2.id-t1.id=1;
--QUERY--
select distinct on(housename) housename, appname
from appliance inner join (
							select housename, applianceid, max(diff) as duration
							from timediff
							group by housename, applianceid
							order by housename, duration desc
						  ) sub on appliance.applianceid=sub.applianceid
order by housename, appname;
--CLEANUP--
drop view v,timediff;

--10--
--QUERY--
select count(*) as numdays
from (select housename from house inner join (
		select distinct on (day) day, houseid
		from (
				select houseid, extract('day' from readingtime) as day, round(cast(avg(powerallphases) as numeric), 2) as avgpower
				from smartmeterdata
				where powerallphases<>-1
				group by houseid, day
				order by day, avgpower asc
			 )  sub1
	 )  sub2 on house.houseid=sub2.houseid) sub3
where housename='House6';

--11--
--PREAMBLE--
create view v as
	select houseid, extract('day' from readingtime) as day, extract('hour' from readingtime) as hour, round(cast(avg(powerallphases) as numeric), 2) as avgpower
	from smartmeterdata
	where powerallphases<>-1
	group by houseid, day, hour;
--QUERY--
select t1.houseid as housea, t2.houseid as houseb, count(*) as numhours
from v as t1 cross join v as t2
where t1.houseid<>t2.houseid
and t1.avgpower>t2.avgpower
and t1.day=t2.day
and t1.hour=t2.hour
group by t1.houseid, t2.houseid
order by t1.houseid, t2.houseid;
--CLEANUP--
drop view v;

--12--
--PREAMBLE--
create view v1 as
	select applianceid, count(*) as den
	from plugdata
	group by applianceid;
create view v2 as
	select applianceid, count(*) as num
	from plugdata
	where power<>-1
	group by applianceid;
--QUERY--
select appname, housename, coverage
from house inner join 
 					 (
 					 	select houseid, appliance.applianceid, appname, coverage
 					 	from appliance inner join 
 					 							(
 					 								select v1.applianceid, round(1.0*v2.num/v1.den,2) as coverage
													from v1 inner join v2
 													on v1.applianceid=v2.applianceid
 					 							) sub1 on appliance.applianceid=sub1.applianceid
 					 ) sub2 on house.houseid=sub2.houseid
order by housename, appname;
--CLEANUP--
drop view v1,v2;

--13--
--QUERY--
select sum(totalpower)/5 as avgpower
from (
		select date_part('week',readingtime) as week, round(cast(avg(powerallphases) as numeric),2) as totalpower
		from smartmeterdata
		where houseid = (select houseid
				      	 from house
						 where housename='House3')
		and powerallphases<>-1
		group by houseid, week
)sub;
