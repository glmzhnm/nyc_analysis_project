[StagingDefinition = [Kind = "FastCopy"]]
section Section1;
[DataDestinations = {[Definition = [Kind = "Reference", QueryName = "Query1_DataDestination", IsNewTarget = true], Settings = [Kind = "Automatic", TypeSettings = [Kind = "Table"]]]}]
shared Query1 = let
    Source = Web.Contents("https://api.worldbank.org/v2/country/USA/indicator/NY.GDP.MKTP.CD?format=json&per_page=50"),
    Json = Json.Document(Source),
    Data = Json{1},
    ToTable = Table.FromList(Data, Splitter.SplitByNothing()),
    Expanded = Table.ExpandRecordColumn(ToTable, "Column1", {"countryiso3code", "date", "value"}, {"country_code", "year", "gdp_usd"}),
    Filtered = Table.SelectRows(Expanded, each [gdp_usd] <> null),
    Typed = Table.TransformColumnTypes(Filtered, {{"country_code", type text}, {"year", Int64.Type}, {"gdp_usd", type number}})
in
    Typed;
shared Query1_DataDestination = let
  Pattern = Lakehouse.Contents([CreateNavigationProperties = false, EnableFolding = false, HierarchicalNavigation = true, EnableVorder = true, OutputMetadataRefresh = true]),
  Navigation_1 = Pattern{[workspaceId = "810ee466-414b-424c-b485-511a26f2a117"]}[Data],
  Navigation_2 = Navigation_1{[lakehouseId = "a629ca4d-feb5-4fab-ade3-74b09e46bc51"]}[Data],
  Navigation_3 = Navigation_2{[Id = "dbo", ItemKind = "Schema"]}[Data],
  TableNavigation = Navigation_3{[Id = "bronze_gdp", ItemKind = "Table"]}?[Data]?
in
  TableNavigation;
