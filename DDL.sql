CREATE DATABASE CMS_GROUP_20
GO
USE CMS_GROUP_20
GO


----PERSON ENTITY (TO STORE ALL THE USERS BOTH CUSTOMERS AND EMPLOYEES----------------

CREATE TABLE PERSON (
UserName NVARCHAR(40) not null, 
[Name] VARCHAR(30) not null,
[Email] VARCHAR(20) not null,
[PhoneNo] BIGINT, 
UserType CHAR(2)
CONSTRAINT UserType_CHK CHECK (UserType in ('C','E')),
CONSTRAINT PERSON_PK PRIMARY KEY (UserName));

-------CUSTOMER ENTITY CONTAINS THE USERS WHO MAKE THR ORDERS FOR THEIR COURIER--------------------

CREATE TABLE CUSTOMER
(
    UserName nvarchar(40) not null,
    Cust_Address varchar(30),
	CustomerCity VARCHAR(20), 
    CustomerState CHAR(20),
    CustomerCountry CHAR(20),
    CustomerPostalCode VARCHAR(9) 
   CONSTRAINT CUSTOMER_PK PRIMARY KEY (UserName),
   CONSTRAINT CUSTOMER_FK FOREIGN key (UserName) references PERSON(UserName)
);
-----------EMPLOYEE ENTITY CONTAINS THE USERS WHO TAKE THE ORDER FROM THE CUSTOMER    -------------------------
-----------EMPLOYEE ENTITY CONTAINS THE USERNAMES OF BOTH ADMIN AND DELIVERY EMPLOYEE -------------------------


CREATE TABLE EMPLOYEE ( 
UserName NVARCHAR(40) not null, 
EmpMonthlyIncome DECIMAL(10,2),
EmpType char(2) CONSTRAINT EmpType_CHK CHECK (EmpType in ('A','DE')),
CONSTRAINT Employee_pK PRIMARY KEY (UserName),
CONSTRAINT Employee_FK FOREIGN KEY (UserName) REFERENCES PERSON(UserName) 
);

---------- PRODUCT ENTITY CONTAINS THE PRODUCTID FOR DIFFERENT CATEGORIES OF PRODUCTS ---------------------- 

CREATE TABLE PRODUCT ( 
ProductID int not null IDENTITY(1,1), 
ProductType NVARCHAR(30) CONSTRAINT ProductType_CHK CHECK (ProductType in ('Furniture','Metals','Food','Others')),
CONSTRAINT PRODUCT_PK PRIMARY KEY (ProductID)
);
---------- ORDER ENTITY CONTAINS THE DETAILS OF THE ORDERS MADE BY THE CUSTOMER ------------------

CREATE TABLE [ORDER] (
OrderID int not null IDENTITY(1,1),
UserName NVARCHAR(40) not null,
SourceAddr NVARCHAR(60) not null,
DestinationAddr NVARCHAR(60) not null, 
DateOfOrder DATETIME DEFAULT ( getdate()),
OrderType VARCHAR(30) CONSTRAINT OrderType_CHK CHECK (OrderType in ('Firstclass','Express','Priority')),
CONSTRAINT ORDER_PK PRIMARY KEY (OrderID),
CONSTRAINT ORDER_FK FOREIGN KEY (UserName) REFERENCES PERSON (UserName)
);

--------------------ORDERLINE CONTAINS THE PRODUCT INFORMATION CONTAINED IN ORDER -------------------------------------------------


CREATE TABLE ORDER_LINE (
OrderID int not null ,
ProductID int not null, 
ProductQuantity smallint, 
ProductWeight decimal(10) 
CONSTRAINT OrderLine_PK PRIMARY KEY (OrderID, ProductID), 
CONSTRAINT OrderLine_FK1 FOREIGN KEY (OrderID) REFERENCES [Order] (OrderID), 
CONSTRAINT OrderLine_FK2 FOREIGN KEY( ProductID) REFERENCES Product (ProductID) 
);

--------------------CREATES INVOICE FOR ORDER -------------------------------------

CREATE TABLE INVOICE ( 
InvoiceID Bigint not null IDENTITY(11111111,1),
OrderID int not null, 
[Date] Datetime default (getdate()),
TotalAmount FLOAT, 
PaymentStatus VARCHAR(15), 
CONSTRAINT PaymentStatus_CHK CHECK (PaymentStatus in ('paid','notpaid')),
PaymentType CHAR(5)
CONSTRAINT PaymentType_CHK CHECK (PaymentType in ('CD','CP')),
CONSTRAINT INVOICE_PK PRIMARY KEY (InvoiceID), 
CONSTRAINT INVOICE_FK FOREIGN KEY (OrderID) REFERENCES [ORDER](OrderID) 
); 
----------------------CREATE CARD ENTITY FOR STORING THE CARD INFORMATION OF THE CUSTOMER TRANSACTION--------------------

CREATE TABLE [CARD](
CardID int not null IDENTITY(1,1),
InvoiceID bigint not null,
CardNo BIGINT not null,
Cardtype VARCHAR(15),
CONSTRAINT CARD_PK PRIMARY KEY (CardID),
CONSTRAINT CARD_FK FOREIGN KEY (InvoiceID) REFERENCES [INVOICE] (InvoiceID) 
);
------------CREATE COUPON ENTITY FOR STORING THE COUPON NUMBER INFORMATION OF THE CUSTOMER TRANSACTION------------------

CREATE TABLE [COUPON](
CouponID int not null IDENTITY(1,1),
CouponNo BIGINT not null,
InvoiceID Bigint not null,
CONSTRAINT CouponNo_PK PRIMARY KEY (CouponID),
CONSTRAINT UNQ_COUPON_NO unique (CouponNo),
CONSTRAINT COUPON_FK FOREIGN KEY (InvoiceID) REFERENCES INVOICE(InvoiceID) 
);
----------DELIVERY EMPLOYEE DETAILS-------------------------

CREATE TABLE Delivery_Employee(
Rating FLOAT, 
OrderID INT not null,
[UserName] NVARCHAR(40) not null 
CONSTRAINT Delivery_Employee_FK1 FOREIGN KEY (OrderID) REFERENCES [ORDER](OrderID),
CONSTRAINT Delivery_Employee_FK2 FOREIGN KEY (UserName) REFERENCES EMPLOYEE(UserName)
);
-------------------ADMIN DETAILS-----------------------------------------------

CREATE TABLE [ADMIN](
 AccessCode int not null,
 Branch_Address nvarchar(100) not null,
 CONSTRAINT UNQ_Accesscode unique (AccessCode),
 [UserName] NVARCHAR(40) not null 
 CONSTRAINT ADMIN_PK PRIMARY KEY (AccessCode),
 CONSTRAINT ADMIN_FK FOREIGN KEY (UserName) REFERENCES EMPLOYEE(UserName)
);
-------------------SHIPMENT CONTAINS ALL THE INFORMATION OF AN ORDER-----------------------------------------------------

CREATE TABLE SHIPMENT(
TrackingNo BIGINT not null IDENTITY(1000,1),
InvoiceID bigint not null,
OrderID int not null,
Employee_Username NVARCHAR(40) not null,
[Status] NVARCHAR(40) not null,
CONSTRAINT SHIPMENT_PK PRIMARY KEY (TrackingNo),
CONSTRAINT SHIPMENT_FK1 FOREIGN KEY (InvoiceID) REFERENCES INVOICE(InvoiceID),
CONSTRAINT SHIPMENT_FK2 FOREIGN KEY (OrderID) REFERENCES [ORDER](OrderID),
CONSTRAINT SHIPMENT_FK3 FOREIGN KEY (Employee_Username) REFERENCES EMPLOYEE(UserName)
);


Select * from PERSON;
select * from CUSTOMER;
select * from EMPLOYEE;
select * from Delivery_Employee;
select * from [ADMIN];
select * from [ORDER];
select * from ORDER_LINE;
select * from PRODUCT;
select * from INVOICE;
select * from [CARD];
select * from COUPON;
select * from SHIPMENT;