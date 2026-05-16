[StagingDefinition = [Kind = "FastCopy"]]
section Section1;
[DataDestinations = {[Definition = [Kind = "Reference", QueryName = "Query1_DataDestination", IsNewTarget = true], Settings = [Kind = "Manual", AllowCreation = true, ColumnSettings = [Mappings = {[SourceColumnName = "location_id", DestinationColumnName = "location_id"], [SourceColumnName = "location_name", DestinationColumnName = "location_name"], [SourceColumnName = "locality", DestinationColumnName = "locality"], [SourceColumnName = "country_code", DestinationColumnName = "country_code"], [SourceColumnName = "country_name", DestinationColumnName = "country_name"], [SourceColumnName = "latitude", DestinationColumnName = "latitude"], [SourceColumnName = "longitude", DestinationColumnName = "longitude"], [SourceColumnName = "first_measurement_utc", DestinationColumnName = "first_measurement_utc"], [SourceColumnName = "last_measurement_utc", DestinationColumnName = "last_measurement_utc"], [SourceColumnName = "sensor_id", DestinationColumnName = "sensor_id"], [SourceColumnName = "sensor_name", DestinationColumnName = "sensor_name"], [SourceColumnName = "param_name", DestinationColumnName = "param_name"], [SourceColumnName = "param_units", DestinationColumnName = "param_units"], [SourceColumnName = "param_displayName", DestinationColumnName = "param_displayName"]}], DynamicSchema = true, UpdateMethod = [Kind = "Replace"], TypeSettings = [Kind = "Table"]]]}]
shared Query1 = let
    Source = Json.Document(Web.Contents(
        "https://api.openaq.org/v3/locations?coordinates=40.7128,-74.0060&radius=25000&limit=1000",
        [Headers=[#"X-API-Key"="dfffa5c2c33d4a797b573152d3bab9008d2c3e7a3b8bf4a0f420244a1015f93f"]]
    )),
    results = Source[results],
    ToTable = Table.FromList(results, Splitter.SplitByNothing()),
    ExpandLocation = Table.ExpandRecordColumn(ToTable, "Column1", {"id", "name", "locality", "country", "coordinates", "datetimeFirst", "datetimeLast", "sensors"}),
    ExpandCoords = Table.ExpandRecordColumn(ExpandLocation, "coordinates", {"latitude", "longitude"}),
    ExpandCountry = Table.ExpandRecordColumn(ExpandCoords, "country", {"code", "name"}, {"country_code", "country_name"}),
    ExpandDateFirst = Table.ExpandRecordColumn(ExpandCountry, "datetimeFirst", {"utc"}, {"first_measurement_utc"}),
    ExpandDateLast = Table.ExpandRecordColumn(ExpandDateFirst, "datetimeLast", {"utc"}, {"last_measurement_utc"}),
    ExpandSensors = Table.ExpandListColumn(ExpandDateLast, "sensors"),
    ExpandSensors2 = Table.ExpandRecordColumn(ExpandSensors, "sensors", {"id", "name", "parameter"}, {"sensor_id", "sensor_name", "parameter"}),
    ExpandParameter = Table.ExpandRecordColumn(ExpandSensors2, "parameter", {"name", "units", "displayName"}, {"param_name", "param_units", "param_displayName"}),
    FilterPollutants = Table.SelectRows(ExpandParameter, each List.Contains({"pm25", "no2", "o3", "pm10", "co"}, [param_name])),
    RenamedCols = Table.RenameColumns(FilterPollutants, {{"id", "location_id"}, {"name", "location_name"}}),
  #"Changed column type" = Table.TransformColumnTypes(RenamedCols, {{"location_id", Int64.Type}, {"sensor_id", Int64.Type}, {"location_name", type text}, {"locality", type text}, {"country_code", type text}, {"country_name", type text}, {"first_measurement_utc", type text}, {"last_measurement_utc", type text}, {"sensor_name", type text}, {"param_name", type text}, {"param_units", type text}, {"param_displayName", type text}, {"latitude", type number}, {"longitude", type number}})
in
    #"Changed column type";
shared Query1_DataDestination = let
  Pattern = Lakehouse.Contents([CreateNavigationProperties = false, EnableFolding = false, HierarchicalNavigation = true, EnableVorder = true, OutputMetadataRefresh = true]),
  Navigation_1 = Pattern{[workspaceId = "810ee466-414b-424c-b485-511a26f2a117"]}[Data],
  Navigation_2 = Navigation_1{[lakehouseId = "a629ca4d-feb5-4fab-ade3-74b09e46bc51"]}[Data],
  Navigation_3 = Navigation_2{[Id = "dbo", ItemKind = "Schema"]}[Data],
  TableNavigation = Navigation_3{[Id = "bronze_openaq", ItemKind = "Table"]}?[Data]?
in
  TableNavigation;
