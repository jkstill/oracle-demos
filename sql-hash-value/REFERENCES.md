
Some references that may be useful


https://www.lab128.com/all_these_oracle_ids/article_text_sql_ids/
https://carlos-sierra.net/2013/09/12/function-to-compute-sql_id-out-of-sql_text
https://externaltable.blogspot.com/2012/06/sql-signature-text-normalization-and.html
https://titanwolf.org/Network/Articles/Article?AID=913edc40-8f79-47b8-92a4-c0739af9aefa#gsc.tab=0
http://blog.tanelpoder.com/2009/02/22/sql_id-is-just-a-fancy-representation-of-hash-value/
https://externaltable.blogspot.com/2012/06/sql-signature-text-normalization-and.html
http://mvelikikh.blogspot.com/2019/07/vdbpipes-unveiling-truth-of-oracle-hash.html

As per "Querying V$Access Contents On Latch: Library Cache (Doc ID 757280.1)"
it may be necessary to append chr(0), and/or other magic cookies to the object being hashed



