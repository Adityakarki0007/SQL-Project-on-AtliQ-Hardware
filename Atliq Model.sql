1.Provide the list in which customer "Croma" operates its business in the Fiscal Year 2021.

Query:
   SELECT * FROM fact_sales_monthly
   WHERE customer_code =  90002002 and get_fiscal_year(date)= 2021  #Customer_Code is the Code number of Croma 
   ORDER BY date DESC                                               #get_Fisal_year is an user defined function
   
---------------------------------------------------------------------------------------------------------------
   
2.Get the complete report of  Total Gross Price of the customer “Croma” in the Fiscal year 2021.
  This analysis helps to get an idea of low and
  high-performing months and take strategic decisions.

  The final report contains these columns:
  Date,Product_Code,Product,Variant,Sold_quantity
  Gross_price per item ,Gross_price total.

Query: 
	SELECT  
    s.date,p.product , p.variant , s.sold_quantity, g.gross_price ,
    ROUND(g.gross_price*s.sold_quantity,2) as gross_price_total
    
    FROM fact_sales_monthly s
    JOIN dim_product p ON s.product_code = p.product_code
    JOIN  fact_gross_price g 
       ON g.product_code = s.product_code
       AND g.fiscal_year = get_fiscal_year(s.date)
    WHERE customer_code =  90002002 and get_fiscal_year(date)= 2021
	ORDER BY date asc

---------------------------------------------------------------------------------------------------------------

3. Generate a report which contains Monthly wise Total Gross price in the "Indian" market
   for "Croma" customer.

   The final report contains these columns:
   date, Total gross price


Query:
       select 
	   s.date, ROUND(SUM(s.sold_quantity * g.gross_price),2) as Total_Gross_Price
       
       FROM fact_sales_monthly s
	   JOIN  fact_gross_price g 
          ON g.product_code = s.product_code
          AND g.fiscal_year = get_fiscal_year(s.date)
       WHERE customer_code =  90002002
       Group By date
       ORDER BY date asc

---------------------------------------------------------------------------------------------------------------

4. Get the complete ( Total Quantity sold ) By Indian Market.

Query:
       select 
       sum(sold_quantity) as total_Quantity
       
       FROM fact_sales_monthly S
       Join dim_customer c 
          ON s.customer_code = c.customer_code
       WHERE c.market="India" and get_fiscal_year(s.date)=2021
       GROUP BY market

---------------------------------------------------------------------------------------------------------------

5. Get the complete report Generating  TOP Market , TOP Products and TOP Customers for the fiscal year 2021
   with respect to the Total Gross price.
   This analysis will help to take strategic decision.

Query:
       SELECT  
       s.date, s.product_code , 
       p.product , p.variant , s.sold_quantity, g.gross_price ,
       ROUND(g.gross_price*s.sold_quantity,2) as gross_price_total

       FROM fact_sales_monthly s
	   JOIN dim_product p
            ON s.product_code = p.product_code
       JOIN  fact_gross_price g 
            ON g.product_code = s.product_code
            AND g.fiscal_year = get_fiscal_year(s.date)

	WHERE  get_fiscal_year(date)= 2021
	ORDER BY gross_price_total desc
    
    
 PART (II) of the above Query :
 We found that the query is taking more time to run the operation ,
# so we did ( Explain Analyze ) 
  and fixed the issue  by adding a separate column for fiscal_year
  in sales_monthly (s) table , so that query takes less time to give the output.
  Hence [Improving the Performance of the Query]
         
Query:

         SELECT  
		s.fiscal_year, c.market as Top_Market , c.customer as Top_Customer,
        p.product as Top_Product , 
        ROUND(g.gross_price*s.sold_quantity,2) as gross_price_total
	

        FROM fact_sales_monthly s
        JOIN dim_product p
              ON s.product_code = p.product_code
        JOIN  fact_gross_price g 
             ON g.product_code = s.product_code
             AND g.fiscal_year = s.fiscal_year
	    JOIN dim_customer c
             ON c.customer_code = s.customer_code
        WHERE s.fiscal_year = 2021
        ORDER BY gross_price_total desc 
        LIMIT 1000000 

---------------------------------------------------------------------------------------------------------------

6.Generate a report which contains Pre Invoice discount, Net invoice sale and  Post Invoice Discount. 
 
Query part (I) - for Pre Invoice discount ( I added this in View Table ) :

                   SELECT  
                      s.date,s.fiscal_year, s.product_code , s.customer_code, c.market,
                      p.product , p.variant , s.sold_quantity, g.gross_price ,
                      ROUND(g.gross_price*s.sold_quantity,2) as gross_price_total,
					  pre.pre_invoice_discount_pct

                      FROM fact_sales_monthly s
					  JOIN dim_product p
							ON s.product_code = p.product_code
                      JOIN  fact_gross_price g 
                            ON g.product_code = s.product_code
                            AND g.fiscal_year = s.fiscal_year
                      JOIN fact_pre_invoice_deductions pre 
                            ON pre.customer_code = s.customer_code
                            AND pre.fiscal_year = s.fiscal_year
                      JOIN dim_customer c
							ON c.customer_code = s.customer_code
     
Query part (II) - for Post Invoice discount ( I added this in View Table ) :

					select
                        ss.date,ss.fiscal_year, ss.product_code , ss.customer_code, ss.market,
                        ss.product , ss.variant , ss.sold_quantity, ss.gross_price_total,
                        ss.pre_invoice_discount_pct, 
					(ss.gross_price_total - ss.gross_price_total *ss. pre_invoice_discount_pct) as net_invoice_sale,
					(pp.discounts_pct + pp.other_deductions_pct) as post_invoice_discount_pct

                     from pre_invoice ss
                     JOIN fact_post_invoice_deductions pp
					      ON pp.customer_code = ss.customer_code
                          AND pp.date = ss.date
                          AND pp.product_code = ss.product_code

---------------------------------------------------------------------------------------------------------------

7. Provide two separate report which contain top 5 market and customer by net_sale in million.
     
     #First I'll make a table of Net Sale  with the help Of [ Post Invoice (View Table) ]
         
	Query :
                       SELECT 
                             *,
                             (1-post_invoice_discount_pct) * net_invoice_sale as Net_sale
					  FROM gdb0041.post_invoice   
                      
	#Top Market By Net Sale
     
	 Query :
              
              SELECT
                 market,
				round(SUM(net_sale)/1000000,2) AS Net_sale_million

				FROM gdb0041.net_sale       # Net Sale Table
                WHERE fiscal_year = 2021
				group by market
                order by net_sale_million desc
                limit 5
 
 #Top customer by net_sale
 
     Query:
                  SELECT
                          cc.customer,
						round(SUM(net_sale)/1000000,2) AS Net_sale_million
                        
				 FROM gdb0041.net_sale nn
				 JOIN dim_customer cc
                        ON cc.customer_code = nn.customer_code
                        AND cc.market = nn.market
				 WHERE fiscal_year = 2021 
                 group by cc.customer
                 order by net_sale_million desc
				 limit 5
  
  ---------------------------------------------------------------------------------------------------------------

8. Generate a report which contains Net Sale percentage.

    #Here I'm Making use of Common Table Expression [Cte]
     Because we cannot use derived Column in select statement.
     
Query :
		with as cte1 (SELECT
                            cc.customer,
                            round(SUM(net_sale)/1000000,2) AS Net_sale_million

					 FROM gdb0041.net_sale nn
					 JOIN dim_customer cc
						ON cc.customer_code = nn.customer_code
                        AND cc.market = nn.market
                     WHERE fiscal_year = 2021 
                     group by cc.customer
                     order by net_sale_million desc
                     )
 
      Select 
            * ,
            net_sale_million*100/sum(net_sale_million) over() as  net_pct
      From cte1
	  Order by net_sale_mill  desc
 
 
--------------------------------------------------------------------------------------------------------------- 
 
9. Get the complete report of Top 5 Customer in The  'INDIAN' Market in fiscal year 2021
   who genrated maxmimun Net sale.This analysis help to get an idea of Premium Customer.

Query :
         SELECT
                 cc.customer,
                 round(SUM(net_sale)/1000000,2) AS Net_sale_million

	   FROM gdb0041.net_sale nn
       JOIN dim_customer cc
           ON cc.customer_code = nn.customer_code
           AND cc.market = nn.market
       WHERE fiscal_year = 2021 and cc.market = "India"
       group by cc.customer
       order by net_sale_million desc
       limit 5 

