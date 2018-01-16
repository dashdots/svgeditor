module Main exposing (..)

import Html exposing (Html, button, div, text, node, p, img)
import Svg exposing (svg, ellipse, rect)
import Svg.Attributes exposing (..)
import Html.Events exposing (onClick, onInput, onMouseDown)
import Html.Attributes exposing (value, checked, src, attribute)
import Ui.Button
import Ui.Chooser
import Tuple exposing (first, second)
import Set exposing (Set)
import Types exposing (..)
import Debug exposing (..)
import Utils
import ShapeMode
import HandMode
import NodeMode
import ViewBuilder
import Parsers
import Actions
import Dict exposing (Dict)

main : Program Never Model Msg
main =
  Html.program { init = init, view = view, update = update, subscriptions = subscriptions }


-- MODEL

init : ( Model, Cmd Msg )
init =
    {
      mode = HandMode,
      dragBegin = Nothing,
      isMouseDown = False,
      svg = {style = Dict.empty, id = -1, attr = Dict.empty, shape = SVG {elems = [], size = (400, 400)}},
      styleInfo = Dict.fromList [("fill", "#883333"), ("stroke", "#223366")],
      idGen = 0,
      selected = Set.empty,
      fixedPoint = Nothing,
      nodeId = Nothing,
      selectedRef = [],
      clientLeft = 0,
      clientTop = 0,
      encoded = "",
      menus = [
        ("Hand", Ui.Button.model "Hand" "primary" "medium"),
        ("Node", Ui.Button.model "Node" "primary" "medium"),
        ("Rect", Ui.Button.model "Rect" "primary" "medium"),
        ("Ellipse", Ui.Button.model "Ellipse" "primary" "medium"),
        ("Polygon", Ui.Button.model "Polygon" "primary" "medium"),
        ("Path", Ui.Button.model "Path" "primary" "medium")
      ],
      actions = [
        Ui.Button.model "Copy" "primary" "small",
        Ui.Button.model "Delete" "primary" "small",
        Ui.Button.model "Bring forward" "primary" "small",
        Ui.Button.model "Send backward" "primary" "small"
      ],
      fillColorChooser = Ui.Chooser.init ()
        |> Ui.Chooser.items [
          {label = "none", value = "none", id = "0"},
          {label = "single", value = "single", id = "1"}
        ]
    } ! [Utils.getSvgData ()]


-- UPDATE

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    OnProperty changePropertyMsg ->
      let
        btnnames = ["Hand", "Node", "Rect", "Ellipse", "Polygon", "Path"]
        btnTpls = List.map (\k -> (k, Ui.Button.model k "primary" "medium")) btnnames
        stressed name = Utils.insertLikeDict name (Ui.Button.model name "success" "medium") btnTpls
      in
      case changePropertyMsg of
        SwichMode HandMode ->
          {model | mode = HandMode, menus = stressed "Hand"} ! []
        
        SwichMode NodeMode ->
          {model | mode = NodeMode, menus = stressed "Node"} ! []

        SwichMode RectMode ->
          {model | mode = RectMode, menus = stressed "Rect"} ! [Utils.getBoundingClientRect "root"]

        SwichMode EllipseMode ->
          {model | mode = EllipseMode, menus = stressed "Ellipse"} ! [Utils.getBoundingClientRect "root"]
        
        SwichMode PolygonMode ->
          {model | mode = PolygonMode, menus = stressed "Polygon"} ! [Utils.getBoundingClientRect "root"]
        
        SwichMode PathMode ->
          {model | mode = PathMode, menus = stressed "Path"} ! [Utils.getBoundingClientRect "root"]        

        Style styleInfo -> case model.mode of
          HandMode ->
            let newModel = HandMode.changeStyle styleInfo model in
            if model /= newModel then newModel ! [Utils.reflectSvgData newModel]
            else model ! []
          NodeMode ->
            let newModel = HandMode.changeStyle styleInfo model in
            if model /= newModel then newModel ! [Utils.reflectSvgData newModel]
            else model ! []
          _ -> {model| styleInfo = styleInfo} ! []
    
    OnAction action -> case action of
      Duplicate ->
        (Actions.duplicate model) ! []
      Delete ->
        (Actions.delete model) ! []
      BringForward ->
        (Actions.bringForward model) ! []
      SendBackward ->
        (Actions.sendBackward model) ! []

    OnMouse onMouseMsg -> case model.mode of
      HandMode ->
        let newModel = HandMode.update onMouseMsg model in
        if model /= newModel then newModel ! [Utils.reflectSvgData newModel]
        else model ! []
      NodeMode ->
        let newModel = NodeMode.update onMouseMsg model in
        if model /= newModel then newModel ! [Utils.reflectSvgData newModel]
        else model ! []
      _ ->
        case onMouseMsg of
          -- マウス押しはここではなく、svgの枠で判定する
          MouseDownLeft pos -> model ! []
          MouseDownRight pos -> model ! []
          _ -> case model.mode of
            PolygonMode ->
              let newModel = ShapeMode.updatePolygon onMouseMsg model in
              if model /= newModel then newModel ! [Utils.reflectSvgData newModel]
              else model ! []
            PathMode ->
              let newModel = ShapeMode.updatePath onMouseMsg model in
              if model /= newModel then newModel ! [Utils.reflectSvgData newModel]
              else model ! []
            _ ->
              let newModel = ShapeMode.update onMouseMsg model in
              if model /= newModel then newModel ! [Utils.reflectSvgData newModel]
              else model ! []
    
    OnSelect ident isAdd pos -> case model.mode of
      HandMode -> (HandMode.select ident isAdd pos model) ! [Utils.getStyle ("svgeditor" ++ (toString ident))]
      NodeMode -> (NodeMode.select ident pos model) ! [Utils.getStyle ("svgeditor" ++ (toString ident))]
      _ -> model ! []
    
    FieldSelect (button, pos) -> case model.mode of
      HandMode -> (HandMode.noSelect model) ! []
      NodeMode -> (NodeMode.noSelect model) ! []
      _ ->
        let
          onMouseMsg = case button of
            0 -> MouseDownLeft pos
            _ -> MouseDownRight pos
        in case model.mode of
          PolygonMode ->
            let newModel = ShapeMode.updatePolygon onMouseMsg model in
            if model /= newModel then newModel ! [Utils.reflectSvgData newModel]
            else model ! []
          PathMode ->
            let newModel = ShapeMode.updatePath onMouseMsg model in
            if model /= newModel then newModel ! [Utils.reflectSvgData newModel]
            else model ! []
          _ ->
            let newModel = ShapeMode.update onMouseMsg model in
            if model /= newModel then newModel ! [Utils.reflectSvgData newModel]
            else model ! []
    
    OnVertex fixed mpos -> case model.mode of
      HandMode -> (HandMode.scale fixed mpos model) ! []
      _ -> model ! []
    
    OnNode mpos nodeId -> case model.mode of
      NodeMode -> (NodeMode.nodeSelect nodeId mpos model) ! []
      _ -> model ! []
    
    SvgData svgData ->
      case Parsers.parseSvg svgData of
        Just (nextId, data) -> {model| svg = data, idGen = nextId} ! [Utils.encodeURIComponent svgData]
        Nothing -> model ! []
    
    EncodedSvgData encoded ->
      {model| encoded = "data:image/svg+xml," ++ encoded} ! []
    
    SvgRootRect rect ->
      {model| clientLeft = rect.left, clientTop = rect.top} ! []
    
    ComputedStyle maybeStyle ->
      let
        selectedStyle = case model.selectedRef of -- 選択中のオブジェクトのスタイル
          hd :: tl -> hd.style
          [] -> Dict.empty
        newStyleInfo = case maybeStyle of
          Just styleObject ->
            let
              hexFill = Parsers.normalizeColor styleObject.fill
              hexStroke = Parsers.normalizeColor styleObject.stroke
            in
            Utils.maybeInsert "fill" hexFill << Utils.maybeInsert "stroke" hexStroke <| selectedStyle
          Nothing -> model.styleInfo
      in
      {model| styleInfo = newStyleInfo} ! []
    FillChooserMsg msg_ ->
      let
        ( updatedChooser, cmd ) = Ui.Chooser.update msg_ model.fillColorChooser
      in
      {model| fillColorChooser = updatedChooser} ! [Cmd.map FillChooserMsg cmd]

-- VIEW


view : Model -> Html Msg
view model =
  let styleInfo = model.styleInfo in
  div []
    [ div [] [
        div [] (
          List.map2 Ui.Button.view [
            OnProperty <| SwichMode HandMode,
            OnProperty <| SwichMode NodeMode,
            OnProperty <| SwichMode RectMode,
            OnProperty <| SwichMode EllipseMode,
            OnProperty <| SwichMode PolygonMode,
            OnProperty <| SwichMode PathMode
          ] (List.map second model.menus)
        ),
        div [] (
          List.map2 Ui.Button.view [
            OnAction <| Duplicate,
            OnAction <| Delete,
            OnAction <| BringForward,
            OnAction <| SendBackward
          ] model.actions
        )
      ],
      div [
        id "root",
        Html.Attributes.style [
          ("width", (toString <| Tuple.first <| Utils.getSvgSize model) ++ "px"),
          ("height", (toString <| Tuple.second <| Utils.getSvgSize model) ++ "px")
        ]
      ] [
        -- 画像としてのsvg
        img [
          id "svgimage",
          src <| model.encoded
        ] [],
        -- 当たり判定用svg
        svg [
          width (toString <| Tuple.first <| Utils.getSvgSize model),
          height (toString <| Tuple.second <| Utils.getSvgSize model),
          Utils.onFieldMouseDown FieldSelect
        ]
        ((List.map (ViewBuilder.build model) (Utils.getElems model)) ++ (case model.mode of
          NodeMode -> ViewBuilder.buildNodes model
          HandMode -> ViewBuilder.buildVertexes model
          _ -> []
        ))
      ],
      div [] [
        text "fill:",
        Html.map FillChooserMsg <| Ui.Chooser.view model.fillColorChooser
      ]
    ]



-- SUBSCRIPTION

subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [
          Utils.getSvgDataFromJs SvgData,
          Utils.encodeURIComponentFromJs EncodedSvgData,
          Utils.getMouseDownLeftFromJs <| OnMouse << MouseDownLeft,
          Utils.getMouseDownRightFromJs <| OnMouse << MouseDownRight,
          Utils.getMouseUpFromJs <| OnMouse << MouseUp,
          Utils.getMouseMoveFromJs <| OnMouse << MouseMove,
          Utils.getBoundingClientRectFromJs SvgRootRect,
          Utils.getStyleFromJs ComputedStyle
        ]