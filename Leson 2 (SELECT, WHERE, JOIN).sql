/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, JOIN".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД WideWorldImporters можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Все товары, в названии которых есть "urgent" или название начинается с "Animal".
Вывести: ИД товара (StockItemID), наименование товара (StockItemName).
Таблицы: Warehouse.StockItems.
*/

select
StockItemID as 'ID товара',
StockItemName as 'Наименование товара' 
from Warehouse.StockItems
where StockItemName like '%urgent%'
or StockItemName like 'Animal%'

/*
2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
Сделать через JOIN, с подзапросом задание принято не будет.
Вывести: ИД поставщика (SupplierID), наименование поставщика (SupplierName).
Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders.
По каким колонкам делать JOIN подумайте самостоятельно.
*/

select
sup.SupplierID,
sup.SupplierName
from Purchasing.Suppliers as sup
left join
Purchasing.PurchaseOrders as orders on
orders.SupplierID = sup.SupplierID
where orders.SupplierID is null

/*
3. Заказы (Orders) с ценой товара (UnitPrice) более 100$ 
либо количеством единиц (Quantity) товара более 20 штук
и присутствующей датой комплектации всего заказа (PickingCompletedWhen).
Вывести:
* OrderID
* дату заказа (OrderDate) в формате ДД.ММ.ГГГГ
* название месяца, в котором был сделан заказ
* номер квартала, в котором был сделан заказ
* треть года, к которой относится дата заказа (каждая треть по 4 месяца)
* имя заказчика (Customer)
Добавьте вариант этого запроса с постраничной выборкой,
пропустив первую 1000 и отобразив следующие 100 записей.

Сортировка должна быть по номеру квартала, трети года, дате заказа (везде по возрастанию).

Таблицы: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/

declare @pgsize int = 100,
@pgnum int = 11

select
o.OrderID,
convert(varchar, o.OrderDate, 104) as [OrderDate],
format(o.OrderDate, 'MMMM', 'ru-ru') as [Месяц заказа],
datepart(quarter, o.OrderDate) as [Квартал],
((month(o.OrderDate) - 1) / 4 + 1) as [Треть года],
cus.CustomerName
from Sales.OrderLines as ol
join Sales.Orders as o on o.OrderID = ol.OrderID
join Sales.Customers cus on cus.CustomerID = o.CustomerID
where (ol.UnitPrice > 100 or ol.Quantity > 20)
and o.PickingCompletedWhen is not null
order by
datepart(quarter, o.OrderDate),
((datepart(month, o.OrderDate) - 1) / 4 + 1),
o.OrderID
offset (@pgnum - 1)* @pgsize rows
fetch next @pgsize rows only

/*
4. Заказы поставщикам (Purchasing.Suppliers),
которые должны быть исполнены (ExpectedDeliveryDate) в январе 2013 года
с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName)
и которые исполнены (IsOrderFinalized).
Вывести:
* способ доставки (DeliveryMethodName)
* дата доставки (ExpectedDeliveryDate)
* имя поставщика
* имя контактного лица принимавшего заказ (ContactPerson)

Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/

select
dm.DeliveryMethodName,		--Application.DeliveryMethods
po.ExpectedDeliveryDate,	--Purchasing.PurchaseOrders
sup.SupplierName,			--Purchasing.Suppliers
p.PreferredName				--Application.People
from Purchasing.PurchaseOrders as po
join Purchasing.Suppliers as sup on po.SupplierID = sup.SupplierID
join Application.DeliveryMethods as dm on po.DeliveryMethodID = dm.DeliveryMethodID
join Application.People as p on p.PersonID = po.ContactPersonID
where po.ExpectedDeliveryDate like '2013-01-%' and
(dm.DeliveryMethodName = 'Air Freight' or dm.DeliveryMethodName = 'Refrigerated Air Freight')
and po.IsOrderFinalized = 1

/*
5. Десять последних продаж (по дате продажи) с именем клиента и именем сотрудника,
который оформил заказ (SalespersonPerson).
Сделать без подзапросов.
*/

select
top 10
o.OrderID,
c.CustomerName as [Имя клиента],
p.FullName as [Имя сотрудника]
from Sales.Orders o
join Sales.Customers c on o.CustomerID = c.CustomerID
join Application.People p on o.SalespersonPersonID = p.PersonID
order by o.OrderDate desc

/*
6. Все ид и имена клиентов и их контактные телефоны,
которые покупали товар "Chocolate frogs 250g".
Имя товара смотреть в таблице Warehouse.StockItems.
*/

select distinct
cus.CustomerID as [ID клиента],
cus.CustomerName as [Имя клиента],
cus.PhoneNumber as [Номер телефона]
from Sales.Orders o
join Sales.OrderLines ol on o.OrderID = ol.OrderID
join Sales.Customers cus on o.CustomerID = cus.CustomerID
join Warehouse.StockItems si on ol.StockItemID = si.StockItemID
where si.StockItemName = 'Chocolate frogs 250g'
order by cus.CustomerID