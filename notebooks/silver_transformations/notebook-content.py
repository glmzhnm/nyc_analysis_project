# Fabric notebook source

# METADATA ********************

# META {
# META   "kernel_info": {
# META     "name": "synapse_pyspark"
# META   },
# META   "dependencies": {
# META     "lakehouse": {
# META       "default_lakehouse": "a629ca4d-feb5-4fab-ade3-74b09e46bc51",
# META       "default_lakehouse_name": "project_lakehouse",
# META       "default_lakehouse_workspace_id": "810ee466-414b-424c-b485-511a26f2a117",
# META       "known_lakehouses": [
# META         {
# META           "id": "a629ca4d-feb5-4fab-ade3-74b09e46bc51"
# META         }
# META       ]
# META     }
# META   }
# META }

# CELL ********************

#Nyc_taxi(bronze to silver)
from pyspark.sql.functions import col, to_date, year, month, hour, dayofweek
file_path = "Files/bronze/taxi/yellow_tripdata_2024-01.parquet"
df_taxi = spark.read.format("parquet").load(file_path)

df_clean = df_taxi.select(
    col("tpep_pickup_datetime").alias("pickup_datetime"),
    col("tpep_dropoff_datetime").alias("dropoff_datetime"),
    col("PULocationID").alias("pickup_zone_id"),
    col("DOLocationID").alias("dropoff_zone_id"),
    col("passenger_count"),
    col("trip_distance"), 
    col("fare_amount"),
    col("total_amount")
)
df_clean = df_clean.filter(
    (col("fare_amount")>0)&
    (col("trip_distance")>0)&
    (col("passenger_count")>0)&
    (col("tpep_pickup_datetime").isNotNull())
)
df_clean = df_clean.dropDuplicates()
df_clean = df_clean\
    .withColumn("pickup_date", to_date(col("pickup_datetime")))\
    .withColumn("pickup_hour", hour(col("pickup_datetime")))\
    .withColumn("pickup_year", year(col("pickup_datetime")))\
    .withColumn("pickup_month", month(col("pickup_datetime")))\
    .withColumn("pickup_dayofweek", dayofweek(col("pickup_datetime")))
df_clean.write.format("delta").mode("overwrite").saveAsTable("silver_taxi")    
display(df_clean.limit(5))




# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

#open_aq(bronze to silver)
df_aq = spark.read.format("delta").load("Tables/dbo/bronze_openaq")
df_silver_aq = df_aq.select(
    col("location_id"),
    col("location_name"),
    col("locality"),
    col("country_code"),
    col("latitude"),
    col("longitude"),
    col("sensor_id"),
    col("param_name"),
    col("param_units"),
    col("param_displayName"),
    col("first_measurement_utc"),
    col("last_measurement_utc")
).filter(
    col("location_id").isNotNull() &
    col("param_name").isNotNull() &
    col("latitude").isNotNull()
).dropDuplicates()
df_silver_aq = df_silver_aq \
    .withColumn("first_measurement_date", to_date(col("first_measurement_utc")))\
    .withColumn("last_measurement_utc", to_date(col("last_measurement_utc")))\
    .withColumn("ingestion_year", year(to_date(col("first_measurement_utc")))) \
    .withColumn("ingestion_month", month(to_date(col("first_measurement_utc"))))
df_silver_aq.write.format("delta").mode("overwrite").saveAsTable("silver_aq")
display(df_silver_aq.limit(5))    

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

#GDP(bronze to silver)
df_gdp = spark.read.format("delta").load("Tables/dbo/bronze_gdp")
df_silver_gdp = df_gdp.select(
    col("country_code"),
    col("year"),
    col("gdp_usd")
).filter(
    col("gdp_usd").isNotNull() &
    col("year").isNotNull()
).dropDuplicates()
df_silver_gdp.write.format("delta").mode("overwrite").saveAsTable("silver_gdp")
display(df_silver_gdp.limit(5))

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

#FX(bronze to silver)
df_fx = spark.read.format("delta").load("Tables/dbo/bronze_fx")
df_silver_fx = df_fx.select(
    col("fx_date"),
    col("usd_eur_rate")
).filter(
    col("fx_date").isNotNull() &
    col("usd_eur_rate").isNotNull() &
    (col("usd_eur_rate")>0)
).dropDuplicates()
df_silver_fx = df_silver_fx \
    .withColumn("fx_year", year(col("fx_date"))) \
    .withColumn("fx_month", month(col("fx_date")))
df_silver_fx.write.format("delta").mode("overwrite").saveAsTable("silver_fx")
display(df_silver_fx.limit(5))

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

import requests
import pandas as pd

url = "https://d37ci6vzurychx.cloudfront.net/misc/taxi_zone_lookup.csv"
response = requests.get(url)

with open("/lakehouse/default/Files/bronze/taxi_zones.csv", "wb") as f:
    f.write(response.content)

df = pd.read_csv("/lakehouse/default/Files/bronze/taxi_zones.csv")
print(df.shape)
display(df.head())
spark_df = spark.createDataFrame(df)
spark_df = spark_df.withColumnRenamed("LocationID", "zone_id") \
                   .withColumnRenamed("Zone", "zone_name") \
                   .withColumnRenamed("Borough", "borough")

spark_df.select("zone_id", "zone_name", "borough") \
        .write.format("delta").mode("overwrite").saveAsTable("silver_zones")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }
