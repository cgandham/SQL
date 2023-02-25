USE CMS_GROUP_20
GO


-------------------------------------------------FUNCTIONS-----------------------------------------------------------------------

--Get Customer Name using OrderID
GO
CREATE FUNCTION GetCustomerEmailWithOrder ( @order_id int ) RETURNS VARCHAR(200)
AS
BEGIN
DECLARE @user NVARCHAR(40)
DECLARE @email VARCHAR(30)
SET @user = (SELECT UserName FROM [ORDER] where OrderID = @order_id);
SET @email = (SELECT Email FROM PERSON where UserName = @user)
return(@email) 
END 


--SELECT dbo.GetCustomerEmailWithOrder(8) AS EMAIL;

--Get the Calculated total Price for Pdts in Order using total Product Weight and no of Quantitys
--input total pdt weight based on orderlines of order and quantity
GO
 CREATE FUNCTION GetOrderPriceByWeight ( 
  @pdt_wt DECIMAL(10,2) ,
  @qty INT 
  )
  RETURNS DECIMAL(10,2)
AS
BEGIN
DECLARE @totalWT DECIMAL(10,2); 
SET @totalWT = @pdt_wt * @qty;
--weight less than 15, price 20 per unit
 IF(@totalWT <=15)
    RETURN @totalWT * 20;
--weight between 16 to 50, price 40 per unit
 ELSE IF( @totalWT <= 50)
    RETURN @totalWT * 40;
--weight above 50, price 50 per unit
	RETURN @totalWT * 50;
END 
GO

SELECT dbo.GetOrderPriceByWeight(51.4,1) AS PRICE;

--------Function to get Product ID using Product Type

GO
CREATE FUNCTION GetProductIDFromType ( @productType NVARCHAR(80) ) RETURNS int
AS
BEGIN
DECLARE @id int
SET @id = (SELECT ProductID FROM PRODUCT where ProductType = @productType)
return(@id) 
END
GO

SELECT dbo.GetProductIDFromType('Food') AS ProductID;

----------------------------------STORED PROCEDURES -----------------------------------------
--Get All Customers based on location
GO
CREATE PROCEDURE SelectCustomersInLocation @City nvarchar(30), @PostalCode nvarchar(10)
AS
BEGIN
SELECT * FROM CUSTOMER WHERE CustomerCity = @City AND CustomerPostalCode = @PostalCode
 IF @@ROWCOUNT = 0
        PRINT 'No customers found from '+ @City +' with postal code '+ @postalCode;
END

EXEC SelectCustomersInLocation @City = 'Boston', @PostalCode = '2215';

--Customer can Track Status of his/her Orders  
GO
CREATE PROCEDURE CustomerOrderStatus @UserName nvarchar(40) AS
BEGIN
select [ORDER].OrderID, [ORDER].SourceAddr, [ORDER].DestinationAddr, [ORDER].DateOfOrder, [ORDER].OrderType, 
SHIPMENT.[Status], SHIPMENT.TrackingNo from [ORDER] join SHIPMENT on SHIPMENT.OrderID = [ORDER].OrderID and [ORDER].UserName=@UserName;
END;

EXEC CustomerOrderStatus 'User01'

----------------------------------------------------------------------------------------------------
-- Admin can assign order to delivery employee
GO
CREATE PROCEDURE SetDeliveryEmp @OrderID int, @Username NVARCHAR(40), @message varchar(500) output AS
BEGIN
	if not exists (select OrderID from [Order] where OrderID=@OrderID) set @message = 'Order does not exist'
	else if not exists (select username from Delivery_Employee where username=@Username) set @message = 'Invalid UserName'
	else if exists (select username from Delivery_Employee where username=@Username)
	BEGIN
		if exists (select OrderID from Delivery_Employee where OrderID=@OrderID) set @message = 'Order already assigned'
		else if not exists (select OrderID from Delivery_Employee where OrderID=@OrderID) 
		BEGIN
			insert into Delivery_Employee values (0.0, @OrderID, @Username);
			set @message = 'Order successfully assigned';
		END
	END
END

DECLARE @Res varchar(500)
EXEC SetDeliveryEmp 16, 'User12', @Res output
PRINT @Res
-------------------------------------------------------------------------------------------------------------------
-- Delivery Employee can view his/her orders
GO
CREATE PROCEDURE DelEmpViewOrders @UserName nvarchar(40) AS
BEGIN
select * from Delivery_Employee where username=@UserName;
END

EXEC DelEmpViewOrders 'User13'
-------------------------------------------------------------------------------------
--Delivery Employee can Update Status of the Order
GO
CREATE PROCEDURE UpdateStatus @UserName nvarchar(40), @StatusChange nvarchar(40),@OrderID int, @message varchar(500) output AS
BEGIN
	if not exists (select Employee_Username from SHIPMENT where Employee_Username=@UserName and OrderID=@OrderID) 
	   set @message = 'Order is not assigned to the Employee'
	if exists (select Employee_Username from SHIPMENT where Employee_Username=@UserName and OrderID=@OrderID)
	BEGIN
		UPDATE SHIPMENT SET [STATUS]=@StatusChange WHERE Employee_Username=@UserName and OrderID=@OrderID;
		set @message = 'Status Updated successfully';
	END
END

DECLARE @Res varchar(500)
EXEC UpdateStatus 'User12', 'Delivered', 1,@Res output
PRINT @Res

---------------------------------------------------------------------------------------
--Add ORDER and OrderLine for Customer
GO
CREATE PROCEDURE PlaceOrder  
    @UserName nvarchar(30),
	@SrcAddr nvarchar(60),
	@DestAddr nvarchar(60),
	@OrderType varchar(30),
	@PdtType NVARCHAR(30),
	@PdtQty smallint,
	@PdtWt decimal(10) ,
	@PaymentType CHAR,
	@Message VARCHAR (30) OUTPUT
AS
BEGIN
IF not exists (select Username from Customer where Username= @UserName) 
  BEGIN
      SET @Message = 'Customer Username does not exist';
  END   
 ELSE
  BEGIN
    DECLARE @OrderID INT;
    INSERT INTO [ORDER] VALUES (@UserName,@SrcAddr,@DestAddr,'',@OrderType);
	SET @OrderID = SCOPE_IDENTITY();
	DECLARE @PdtID int
	SET @PdtID =  dbo.GetProductIDFromType(@PdtType);
	PRINT @PdtID;
	if(@PdtID > 0)
	BEGIN
	  INSERT INTO ORDER_LINE VALUES (@OrderID,@PdtID,@PdtQty,@PdtWt);
	  SET @Message = 'Placed Order Sucessfully';
	END
	else
	  SET @Message = 'Product Type is Invalid';
  END
END
GO


--Create INVOICE for Order
GO
CREATE PROCEDURE AddInvoiceForOrder
	@OrderID int,
	@PdtQty smallint,
	@PdtWt decimal(10) ,
	@PaymentType CHAR(5),
	@PaymentNoParam BIGINT,
	@CardStatus VARCHAR(15) = NULL,--optional param,used in case of Card Payment
	@Message VARCHAR (30) OUTPUT
AS
BEGIN
IF not exists (select * from [ORDER] where OrderID= @OrderID) 
  BEGIN
      SET @Message = 'Invalid Order ID';
  END    
ELSE
  BEGIN
    DECLARE @OrderPrice int
	SELECT @OrderPrice =  dbo.GetOrderPriceByWeight(@PdtWt,@PdtQty);
	DECLARE @InvoiceID INT;
    INSERT INTO INVOICE VALUES(@OrderID,GETDATE(),@OrderPrice,'notpaid',@PaymentType)
	SET @InvoiceID = SCOPE_IDENTITY();
	IF(@PaymentType = 'CP')
	  BEGIN
	   INSERT INTO COUPON VALUES(@PaymentNoParam,@InvoiceID)
	   SET @Message ='Added Invoice for Payment_type COUPON'
	  END
	ELSE IF(@PaymentType = 'CD')
	  BEGIN
	    INSERT INTO [CARD] VALUES(@InvoiceID,@PaymentNoParam,@CardStatus)
		SET @Message ='Added Invoice for Payment_type CARD'
	  END
  END
END

--Create SHIPMENT for Order
GO
CREATE PROCEDURE AddShipmentForOrder
	@OrderID int,
	@InvoiceID int,
	@Admin_UserName  NVARCHAR(40),
	@Message VARCHAR (30) OUTPUT
AS
BEGIN
IF not exists (select * from [ORDER] where OrderID= @OrderID) 
  BEGIN
      SET @Message = 'Invalid Order ID';
  END   
ELSE IF not exists (select * from INVOICE where InvoiceID= @InvoiceID) 
  BEGIN
      SET @Message = 'Invalid Invoice ID';
  END   
 ELSE
  BEGIN
   INSERT INTO SHIPMENT VALUES(@InvoiceID,@OrderID,@Admin_UserName,'Incomplete')
    SET @Message = 'Shipment Added Sucessfully';
  END
END
GO

--PROCEDURE FOR LOGIN FOR THE CUSTOMER ----------

GO
CREATE PROCEDURE customerLoginCheck @UserName nvarchar(40),@Password varbinary(128), @message nvarchar(500) output AS
BEGIN 
   IF not exists (select * from PERSON where UserName=@UserName and [Password]=@Password)
    set @message ='Invalid UserName and Password'
   ELSE 
    set @message = 'CUSTOMER Logged in Successfully'
END

DECLARE @Res varchar(500)
DECLARE @pwd varbinary(MAX)
set @pwd = CONVERT(varbinary(max), CONVERT(nvarchar(max),'pwd'))
EXEC customerLoginCheck 'User02' ,@pwd ,@Res output
PRINT @Res


------PROCEDURE FOR REGISTERING THE CUSTOMER ------------------------------------------------------------------------------------

GO
CREATE PROCEDURE 
customer_registration @UserName NVARCHAR(40),@Password varbinary(128),@Name VARCHAR(30),@Email VARCHAR(20),
@PhoneNo BIGINT,@Cust_Address varchar(30),@CustomerCity VARCHAR(20),@CustomerState CHAR(20),@CustomerCountry CHAR(20),
@CustomerPostalCode VARCHAR(9) ,@message nvarchar(500) output AS
BEGIN
 DECLARE @UserType CHAR(2)
 set @UserType='C';
 IF exists (select UserName from PERSON where UserName=@UserName) 
	set @message='UserName already exists'
 ELSE 
 BEGIN
   INSERT INTO PERSON VALUES(@UserName,@Name,@Email,@PhoneNo,@UserType,@Password);
   INSERT INTO CUSTOMER VALUES(@UserName,@Cust_Address,@CustomerCity,@CustomerState,@CustomerCountry,@CustomerPostalCode);
   set @message ='Customer Registered Successfully'
 END
END

Declare @Res varchar(500)
DECLARE @pwd varbinary(MAX)
set @pwd = CONVERT(varbinary(max), CONVERT(nvarchar(max),'pwd'))
EXEC customer_registration 'User23',@pwd,'cust23','cust23@dm.com' ,'6387923892','Foresthill','Boston','MA','USA','02150',@Res output
PRINT @Res

---------------------------------------------------TRIGGERS-----------------------------------------------------------------
--create trigger to avoid conflict of Product Type Name
GO
CREATE TRIGGER ConflictNameInProduct
ON PRODUCT
AFTER INSERT
AS BEGIN
DECLARE @name NVARCHAR(50)
SELECT @name = ProductType FROM inserted
IF EXISTS (SELECT * FROM PRODUCT WHERE ProductType = @name)
BEGIN
RAISERROR('The Product Type already exists. Please Check!',1,1)
DELETE FROM PRODUCT WHERE ProductID = (SELECT ProductID from inserted)
END
END

--INSERT INTO PRODUCT VALUES('Furniture'); select * from PRODUCT;

--create trigger to capture changes in shipment table
-- Used to track progress of the order
GO
CREATE TABLE SHIPMENT_AUDITS( 
 ChangeID INT IDENTITY PRIMARY KEY,
 TrackingNo INT NOT NULL,
 OrderID INT ,
 [Status] NVARCHAR(40),
 Action CHAR(1),
 ActionDate DATETIME
 );
 
 SET QUOTED_IDENTIFIER ON
 GO
CREATE TRIGGER GET_SHIPMENT_AUDITS ON SHIPMENT FOR UPDATE AS
BEGIN
DECLARE @Action char(1)
SET @Action = 'U'
INSERT INTO SHIPMENT_AUDITS( TrackingNo,OrderID,[Status],Action,ActionDate)
SELECT TrackingNo,OrderID,[Status],@Action,GETDATE() FROM DELETED
END
GO

SELECT * FROM SHIPMENT_AUDITS
------------------------------------------------VIEWS-------------------------------------------------------
--View to see details of all pending Orders
GO
CREATE VIEW vw_IncompleteOrders AS 

SELECT o.Username AS Customer_UserName,s.OrderID,s.InvoiceID,s.TrackingNo,s.Employee_Username AS 'DELIVERY EMPLOYEEE' ,s.Status
 FROM SHIPMENT s JOIN [ORDER] o ON o.OrderID = s.OrderID WHERE Status != 'Complete' ;
GO

SELECT * FROM vw_IncompleteOrders


----------CUSTOMER VIEW THE ORDER STATUS----------------
GO
CREATE VIEW vw_Cust_Order_status AS
SELECT C.UserName AS Customer_UserName, S.OrderID , S.[Status] FROM CUSTOMER C 
   JOIN [ORDER] O ON C.UserName = O.UserName  
   JOIN [SHIPMENT] S ON O.OrderID = S.OrderID ;
GO

SELECT * FROM vw_Cust_Order_status

----------------------ADMIN VIEW THE ORDER STATUS-------------

GO
CREATE VIEW vw_Admin_Order_status AS
SELECT  D.OrderID, D.UserName AS Assigned_DeliveryEmp ,S.[Status] FROM [ORDER] O JOIN Delivery_Employee D ON O.OrderID = D.OrderID
JOIN [SHIPMENT] S ON D.OrderID = S.OrderID ;
GO

SELECT * FROM vw_Admin_Order_status

-----------------------------------------------------------------
