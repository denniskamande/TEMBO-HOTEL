--TEMBO HOTEL

create schema  if not exists tembo_hotel;
SET search_path to tembo_hotel;

--CREATING TABLES TO FEED THE DATA.
--ALL FIELDS IN TEXT TO ACCOMODATE ALL DATA TYPES.

create table if not exists tembo_hotel
(

booking_id         	 	TEXT,
guest_name         	 	TEXT,
guest_phone         	TEXT,
guest_city          	TEXT,
guest_nationality 		TEXT,
room_no					TEXT,
room_type 				TEXT,
room_rate_per_night 	TEXT,
check_in_date 			TEXT,
check_out_date 			TEXT,
nights_stayed 			TEXT,
staff_name 				TEXT,
staff_department 		TEXT,
staff_salary 			TEXT,
payment_method 			TEXT,
booking_status 			TEXT,
total_amount 			TEXT,
service_used 			TEXT,
service_price 			TEXT,
guest_rating 			TEXT

);


--IMPORT DATA FROM OUR CSV FILE 

select* from tembo_hotel;

--TABLE LOADED AND READY FOR CLEANING.

--1. REMOVING DUPLICATES FROM THE TABLE.

select
	booking_id
from tembo_hotel;


select
		booking_id,
		count(*) as counts
from tembo_hotel
group by booking_id
having count(*) > 1;      
					 ---removing the duplicate

delete from 
	tembo_hotel
where ctid not in
(select min(ctid) from tembo_hotel group by booking_id);

--2. MAKING ALL THE CASES UNIFORM IN ALL ROWS.
		--Also removing all the spaces before and after the text using trim()
select* from tembo_hotel;

update  tembo_hotel
set guest_name = trim(initcap(guest_name)),
    guest_city = trim(initcap(guest_city)),
	guest_nationality = trim(initcap(guest_nationality)),
	room_type = trim(initcap(room_type)),
	staff_name = trim(initcap(staff_name)),
	payment_method = trim(initcap(payment_method)),
	booking_status = trim(initcap(booking_status)),
	service_used = trim(initcap(service_used));


-- 3. CLEAN THE CITY,ROOM TYPE COLUMNE TO MAKE IT UNIFORM

--city

select 
	distinct(guest_city) 
from tembo_hotel;

update tembo_hotel
set guest_city = nullif(replace(guest_city,'Thikax','Thika'),'');


--roomtype

select 
	distinct(room_type)
from tembo_hotel;

update tembo_hotel
set room_type = case
	when room_type = 'Dlx' then 'Deluxe'
	when room_type = 'Std' then 'Standard'
	else room_type
end;

--payment method
select 
	distinct(payment_method)
from tembo_hotel;


update tembo_hotel
set payment_method = replace(payment_method,'Mpesa','M-Pesa');


-- 4. CLEANING THE PHONE NUMBERS USING REXREPLACE

select guest_phone 
from tembo_hotel;

--removing blanks and spaces

update tembo_hotel
set guest_phone =nullif(regexp_replace(guest_phone,'[^0-9]','','g'),'');

--removing 254 and replacing with 0

update tembo_hotel
set guest_phone = '0'|| substring(regexp_replace(guest_phone,'[^0-9]','','g'),3)
where guest_phone like '254%';

update tembo_hotel
set guest_phone = '0'|| regexp_replace(guest_phone,'[^0-9]','','g')
where guest_phone not like '%[1-9]';


UPDATE tembo_hotel
SET guest_phone = regexp_replace(guest_phone, '^0', '')
WHERE guest_phone LIKE '00%';



--5. CLEAN THE SALARIES AND INTEGERS NEEDED FOR CALCULATION

select* from tembo_hotel;

--staff salary

select staff_salary
from tembo_hotel;

update tembo_hotel
set staff_salary = nullif(regexp_replace(staff_salary,'[^0-9]','','g'),'')
where staff_salary like 'KES%' or staff_salary like '';

--total amount
select total_amount
from tembo_hotel;


update tembo_hotel
set total_amount = nullif(regexp_replace(total_amount,'[^0-9]','','g'),'')
where total_amount like 'KES%' or total_amount like '' or total_amount like ',';




-- 5.CHANGING DATA NEED FOR CALCULATION FROM TEXT TO INTEGERS
select* from tembo_hotel;
 
alter table tembo_hotel
alter column room_rate_per_night type numeric
using room_rate_per_night :: numeric;

--updating nights stayed
update tembo_hotel
set nights_stayed = ABS(nights_stayed);


alter table tembo_hotel
alter column nights_stayed type numeric
using nights_stayed :: numeric;


alter table tembo_hotel
alter column staff_salary type numeric
using staff_salary ::numeric;

--updating column total_amount
update tembo_hotel
set total_amount = nullif(regexp_replace(total_amount,'[^0-9]','','g'),'');


alter table tembo_hotel
alter column total_amount type numeric
using total_amount ::numeric;





--update guest_rating
update tembo_hotel
set guest_rating = nullif(guest_rating,'');

alter table tembo_hotel
alter column guest_rating type numeric
using guest_rating :: numeric;


ALTER TABLE tembo_hotel
ALTER COLUMN check_in_date TYPE date
USING CASE
    WHEN check_in_date LIKE '%/%'
    THEN TO_DATE(check_in_date, 'DD/MM/YYYY')
    ELSE check_in_date::date
END;


 -- 6. Create Production Table & Load Clean Data

INSERT INTO tembo (
    booking_id,
    guest_city,
    room_number,
    room_type,
    check_in_date,
    check_out_date,
    nights_stayed,
    staff_name,
    staff_department,
    staff_salary,
    payment_method,
    booking_status,
    total_amount,
    guest_rating
)
SELECT
    booking_id,
    guest_city,
    room_no,
    room_type,
    check_in_date,
    check_out_date,
    nights_stayed,
    staff_name,
    staff_department,
    staff_salary,
    payment_method,
    booking_status,
    total_amount,
    guest_rating
FROM tembo_hotel;





select* from tembo;




/* Business questions:
1.	Revenue analysis: Total revenue by month, by room type, by payment method
2.	Occupancy: Which room types are booked most? Average nights stayed per room type
3.	Guest insights: Top 10 cities guests come from. Average rating per room type
4.	Staff performance: Which staff handled the most bookings? Which department generates most revenue?
5.	Trends: Revenue growth month over month (window function). Busiest vs quietest months
6.	Cancellations: Cancellation rate per room type. Revenue lost from cancellations and no-shows
*/



-- 1.	Revenue analysis: Total revenue by month, by room type, by payment method

select
	room_type,
	sum(total_amount) as revenue
from tembo
group by room_type
order by revenue;

select
	extract  check_in_date as month,
	sum(total_amount) as revenue
from tembo
group by month
order by revenue;


 -- 2.	Occupancy: Which room types are booked most? Average nights stayed per room type

select 
	room_type, 
	count(room_type) as bookings
from tembo
group by room_type
order by bookings desc;


select 
	room_type,
	round(avg(nights_stayed),1) as average_nights
from tembo
group by room_type
order by average_nights;



---CTE
with room_details as
(
select 
	room_type, 
	count(room_type) as bookings,
	round(avg(nights_stayed),1) as average_nights
from tembo
group by room_type
)
select 
	room_type,
	bookings,
	average_nights
from room_details
order by bookings desc,average_nights;


-- 3.Guest insights: Top 10 cities guests come from. Average rating per room type

select 
	guest_city, 
	count(guest_city) as city_visits
from tembo
group by guest_city
order by city_visits desc;

select 
	room_type,
	round(avg(guest_rating),1) as average_rating
from tembo
group by room_type
order by average_rating desc;

--4.Staff performance: Which staff handled the most bookings? Which department generates most revenue?
select 
	staff_name,
	count(staff_name) as bookings,
	sum(total_amount) as ind_revenue
from tembo
group by staff_name
order by bookings desc,ind_revenue;


select 
	staff_department, 
		sum(total_amount) as revenue
from tembo
group by staff_department
order by revenue desc;

-- 5.Trends: Revenue growth month over month (window function). Busiest vs quietest months

select 
	extract(month from check_in_date,'Month') as month,
	sum(total_amount) as revenue
from tembo 
group by month
order by revenue desc;

with monthly_revenue as
(
	select 
		extract(month from check_in_date) as month,
		to_char(check_in_date,'Month') as month_name,
		sum(total_amount) as revenue
	from tembo 
	group by month,month_name
),
previous_month_revenue as
(
select 
	month, 
	month_name,
	revenue,
	lag(revenue) over(order by month) as previous_revenue
from monthly_revenue
)

select 
	month,
	month_name,
	previous_revenue,
	revenue,
	round(
	(revenue - previous_revenue)/(previous_revenue)*100,1) as growth
from previous_month_revenue
order by month;

-- 6.Cancellations: Cancellation rate per room type. Revenue lost from cancellations and no-shows

select 
    room_type,

    count(*) as total_bookings,

    count(*) filter (
        where booking_status = 'Cancelled'
    ) as  cancellations,

    round(
        count(*) filter  (
            where  booking_status = 'Cancelled'
        )::numeric / COUNT(*) * 100,
        1
    ) as  cancellation_rate,

    sum(total_amount) filter  (
        where  booking_status in  ('Cancelled', 'No Show')
    ) as  revenue_lost

from  tembo
group by  room_type
order by  cancellation_rate desc;
	


select* from tembo;

