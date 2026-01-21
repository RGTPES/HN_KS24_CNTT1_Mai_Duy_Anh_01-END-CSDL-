drop database if exists HN_KS24_CNTT1_MaiDuyAnh_01;
create database HN_KS24_CNTT1_MaiDuyAnh_01;
use HN_KS24_CNTT1_MaiDuyAnh_01;

create table Shippers (
idShipper int primary key,
fullName varchar(100) not null,
phoneNumber varchar(50) unique not null,
driversLicense varchar(50) not null,
voted decimal(2,1) default 5.0,
check (voted between 0 and 5)
);

create table Vehicle_Details(
idVehicle int primary key,
idShipper int not null,
plateNumber varchar(50) unique,
typevihicle enum ('Tải','Xe máy','Container'),
maxWeight int check (maxWeight > 0),
foreign key(idShipper) references Shippers(idShipper)
on update cascade
on delete cascade
);

create table Shipments (
idShipment int primary key,
nameShipment varchar(255),
weight decimal(10,2) check (weight > 0),
price decimal(15,2),
statusShipment enum ('In Transit','Delivered','Returned')
);

create table Delivery_Orders (
idOrder int primary key,
idShipment int,
idShipper int,
timeAceppect datetime default current_timestamp,
priceDelivery decimal(15,2),
statusOrder enum ('Pending','Processing','Finished','Cancelled'),
foreign key(idShipment) references Shipments(idShipment),
foreign key(idShipper) references Shippers(idShipper)
on update cascade
on delete cascade
);

create table Delivery_Log (
idLog int auto_increment primary key,
idOrder int,
place varchar(255),
dateAceppect datetime default current_timestamp,
note varchar(255),
foreign key(idOrder) references Delivery_Orders(idOrder)
on update cascade
on delete cascade
);

insert into Shippers values
(1,'Nguyen Van An','0901234567','C',4.8),
(2,'Tran Thi Binh','0912345678','A2',5.0),
(3,'Le Hoang Nam','0983456789','FC',4.2),
(4,'Pham Minh Duc','0354567890','B2',4.9),
(5,'Hoang Quoc Viet','0775678901','C',4.7);

insert into Vehicle_Details values
(101,1,'29C-123.45','Tải',3500),
(102,2,'59A-888.88','Xe máy',500),
(103,3,'15R-999.99','Container',32000),
(104,4,'30F-111.22','Tải',1500),
(105,5,'43C-444.55','Tải',5000);

insert into Shipments values
(5001,'Smart TV Samsung 55 inch',25.5,15000000,'In Transit'),
(5002,'Laptop Dell XPS',2.0,35000000,'Delivered'),
(5003,'Máy nén khí công nghiệp',450.0,120000000,'In Transit'),
(5004,'Thùng trái cây nhập khẩu',15.0,2500000,'Returned'),
(5005,'Máy giặt LG Inverter',70.0,9500000,'In Transit');

insert into Delivery_Orders values
(9001,5001,1,'2024-05-20 08:00:00',2000000,'Processing'),
(9002,5002,2,'2024-05-20 09:30:00',3500000,'Finished'),
(9003,5003,3,'2024-05-20 10:15:00',2500000,'Processing'),
(9004,5004,5,'2024-05-21 07:00:00',1500000,'Finished'),
(9005,5005,4,'2024-05-21 08:45:00',2500000,'Pending');

insert into Delivery_Log(idOrder,place,dateAceppect,note) values
(9001,'Kho tổng (Hà Nội)','2021-05-15 08:15:00','Rời kho'),
(9001,'Trạm thu phí Phủ Lý','2021-05-17 10:00:00','Đang giao'),
(9002,'Quận 1, TP.HCM','2024-05-19 10:30:00','Đã đến điểm đích'),
(9003,'Cảng Hải Phòng','2024-05-20 11:00:00','Rời kho'),
(9004,'Kho hoàn hàng (Đà Nẵng)','2024-05-21 14:00:00','Đã nhập kho trả hàng');

-- phan 1a
update Delivery_Orders d
join Shipments s on d.idShipment = s.idShipment
set d.priceDelivery = d.priceDelivery * 1.1
where d.statusOrder = 'Finished'
and s.weight > 100;

-- phan 1b
delete from Delivery_Log
where dateAceppect < '2024-05-17';

-- phan 2 c1
select plateNumber,typevihicle,maxWeight
from Vehicle_Details
where maxWeight > 5000
or (typevihicle = 'Container' and maxWeight < 2000);

-- phan 2 c2
select fullName,phoneNumber
from Shippers
where voted between 4.5 and 5.0
and phoneNumber like '090%';

-- phan 2 c3
select *
from Shipments
order by price desc
limit 2 offset 2;

-- phan 3 c1
select s.fullName,d.idShipment,sh.nameShipment,d.priceDelivery,d.timeAceppect
from Delivery_Orders d
join Shippers s on d.idShipper = s.idShipper
join Shipments sh on d.idShipment = sh.idShipment;

-- phan 3 c2
select s.fullName,sum(d.priceDelivery) as totalPrice
from Shippers s
join Delivery_Orders d on s.idShipper = d.idShipper
group by s.fullName
having sum(d.priceDelivery) > 3000000;

-- phan 3 c3
select *
from Shippers
where voted = (select max(voted) from Shippers);

-- phan 4 c1
create index idx_shipment_status_value
on Shipments(statusShipment,price);

-- phan 4 c2
create or replace view vw_driver_performance as
select s.fullName,
count(d.idOrder) as totalOrders,
sum(d.priceDelivery) as TotalDelivery
from Shippers s
left join Delivery_Orders d
on s.idShipper = d.idShipper
and d.statusOrder <> 'Cancelled'
group by s.fullName;

-- phan 5 c1
drop trigger if exists trg_after_delivery_finish;
delimiter $$
create trigger trg_after_delivery_finish
after update on Delivery_Orders
for each row
begin
if new.statusOrder = 'Finished' and old.statusOrder <> 'Finished' then
insert into Delivery_Log(idOrder,place,dateAceppect,note)
values(new.idOrder,'Tại điểm đích',now(),'Delivery Completed Successfully');
end if;
end $$
delimiter ;

-- phan 5 c2
drop trigger if exists trg_update_driver_rating;
delimiter $$
create trigger trg_update_driver_rating
after insert on Delivery_Orders
for each row
begin
if new.statusOrder = 'Finished' then
update Shippers
set voted = if(voted + 0.1 > 5, 5, voted + 0.1)
where idShipper = new.idShipper;
end if;
end $$
delimiter ;

-- phan 6 c1
drop procedure if exists sp_check_payload_status;
delimiter $$
create procedure sp_check_payload_status(in p_idVehicle int, out message varchar(20))
begin
declare v_max int;
declare v_weight decimal(10,2);
select v.maxWeight,s.weight
into v_max,v_weight
from Vehicle_Details v
join Delivery_Orders d on v.idShipper = d.idShipper
join Shipments s on d.idShipment = s.idShipment
where v.idVehicle = p_idVehicle
order by d.timeAceppect desc
limit 1;
if v_weight > v_max then
set message = 'Quá tải';
elseif v_weight = v_max then
set message = 'Đầy tải';
else
set message = 'An toàn';
end if;
end $$
delimiter ;

