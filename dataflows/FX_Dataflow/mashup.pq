[StagingDefinition = [Kind = "FastCopy"]]
section Section1;
[DataDestinations = {[Definition = [Kind = "Reference", QueryName = "Query1_DataDestination", IsNewTarget = true], Settings = [Kind = "Automatic", TypeSettings = [Kind = "Table"]]]}]
shared Query1 = let
    Source = Csv.Document(Web.Contents(
        "https://data-api.ecb.europa.eu/service/data/EXR/D.USD.EUR.SP00.A?format=csvdata"
    ), [Delimiter=",", Encoding=65001, QuoteStyle=QuoteStyle.None]),
    Headers = Table.PromoteHeaders(Source),
    Selected = Table.SelectColumns(Headers, {"TIME_PERIOD", "OBS_VALUE"}),
    Renamed = Table.RenameColumns(Selected, {{"TIME_PERIOD", "fx_date"}, {"OBS_VALUE", "usd_eur_rate"}}),
    Typed = Table.TransformColumnTypes(Renamed, {{"fx_date", type date}, {"usd_eur_rate", type number}})
in
    Typed;
shared Query1_DataDestination = let
  Pattern = Lakehouse.Contents([CreateNavigationProperties = false, EnableFolding = false, HierarchicalNavigation = true, EnableVorder = true, OutputMetadataRefresh = true]),
  Navigation_1 = Pattern{[workspaceId = "810ee466-414b-424c-b485-511a26f2a117"]}[Data],
  Navigation_2 = Navigation_1{[lakehouseId = "a629ca4d-feb5-4fab-ade3-74b09e46bc51"]}[Data],
  Navigation_3 = Navigation_2{[Id = "dbo", ItemKind = "Schema"]}[Data],
  TableNavigation = Navigation_3{[Id = "bronze_fx", ItemKind = "Table"]}?[Data]?
in
  TableNavigation;
