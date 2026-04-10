#!/bin/bash
# WDA helper script for Claude Code vision-based testing
# Usage: ./wda.sh <command> [args...]

WDA_URL="http://localhost:8100"
SESSION=""

# Get or create session
get_session() {
  SESSION=$(curl -s -X POST "$WDA_URL/session" \
    -H 'Content-Type: application/json' \
    -d '{"capabilities": {"alwaysMatch": {}}}' | \
    python3 -c "import sys,json; print(json.load(sys.stdin)['value']['sessionId'])")
  echo "$SESSION"
}

case "$1" in
  session)
    get_session
    ;;
  screenshot)
    # Save screenshot to specified path (default: /tmp/iphone_screen.png)
    OUTPUT="${2:-/tmp/iphone_screen.png}"
    curl -s "$WDA_URL/screenshot" | \
      python3 -c "import sys,json,base64; open('$OUTPUT','wb').write(base64.b64decode(json.load(sys.stdin)['value']))"
    echo "$OUTPUT"
    ;;
  tap)
    # Tap at coordinates: ./wda.sh tap <session> <x> <y>
    SESSION="$2"; X="$3"; Y="$4"
    curl -s -X POST "$WDA_URL/session/$SESSION/actions" \
      -H 'Content-Type: application/json' \
      -d "{
      \"actions\": [{
        \"type\": \"pointer\",
        \"id\": \"finger1\",
        \"parameters\": {\"pointerType\": \"touch\"},
        \"actions\": [
          {\"type\": \"pointerMove\", \"duration\": 0, \"x\": $X, \"y\": $Y},
          {\"type\": \"pointerDown\", \"button\": 0},
          {\"type\": \"pause\", \"duration\": 100},
          {\"type\": \"pointerUp\", \"button\": 0}
        ]
      }]
    }" > /dev/null
    echo "Tapped ($X, $Y)"
    ;;
  type)
    # Type text: ./wda.sh type <session> "text"
    SESSION="$2"; TEXT="$3"
    # Find active element and send keys
    ACTIVE=$(curl -s "$WDA_URL/session/$SESSION/element/active" | \
      python3 -c "import sys,json; d=json.load(sys.stdin); print(d['value'].get('ELEMENT',''))" 2>/dev/null)
    if [ -n "$ACTIVE" ]; then
      curl -s -X POST "$WDA_URL/session/$SESSION/element/$ACTIVE/value" \
        -H 'Content-Type: application/json' \
        -d "{\"text\": \"$TEXT\"}" > /dev/null
      echo "Typed: $TEXT"
    else
      echo "No active element to type into"
    fi
    ;;
  swipe)
    # Swipe: ./wda.sh swipe <session> <fromX> <fromY> <toX> <toY>
    SESSION="$2"; FX="$3"; FY="$4"; TX="$5"; TY="$6"
    curl -s -X POST "$WDA_URL/session/$SESSION/actions" \
      -H 'Content-Type: application/json' \
      -d "{
      \"actions\": [{
        \"type\": \"pointer\",
        \"id\": \"finger1\",
        \"parameters\": {\"pointerType\": \"touch\"},
        \"actions\": [
          {\"type\": \"pointerMove\", \"duration\": 0, \"x\": $FX, \"y\": $FY},
          {\"type\": \"pointerDown\", \"button\": 0},
          {\"type\": \"pointerMove\", \"duration\": 800, \"x\": $TX, \"y\": $TY},
          {\"type\": \"pointerUp\", \"button\": 0}
        ]
      }]
    }" > /dev/null
    echo "Swiped ($FX,$FY) -> ($TX,$TY)"
    ;;
  find)
    # Find element by label: ./wda.sh find <session> "label"
    SESSION="$2"; LABEL="$3"
    curl -s -X POST "$WDA_URL/session/$SESSION/elements" \
      -H 'Content-Type: application/json' \
      -d "{\"using\": \"predicate string\", \"value\": \"label == \\\"$LABEL\\\"\"}" | \
      python3 -c "
import sys,json
d = json.load(sys.stdin)
elems = d.get('value', [])
if elems:
    print(elems[0].get('ELEMENT', elems[0].get('element-6066-11e4-a52e-4f735466cecf', '')))
else:
    print('')
"
    ;;
  rect)
    # Get element rect: ./wda.sh rect <session> <element_id>
    SESSION="$2"; ELEM="$3"
    curl -s "$WDA_URL/session/$SESSION/element/$ELEM/rect" | \
      python3 -c "import sys,json; d=json.load(sys.stdin)['value']; print(f'x={d[\"x\"]} y={d[\"y\"]} w={d[\"width\"]} h={d[\"height\"]} center=({d[\"x\"]+d[\"width\"]//2},{d[\"y\"]+d[\"height\"]//2})')"
    ;;
  home)
    # Press home button
    curl -s -X POST "$WDA_URL/wda/homescreen" > /dev/null
    echo "Home pressed"
    ;;
  status)
    curl -s "$WDA_URL/status" | python3 -c "import sys,json; d=json.load(sys.stdin)['value']; print(f'WDA ready={d[\"ready\"]} device={d[\"device\"]} iOS={d[\"os\"][\"version\"]}')"
    ;;
  *)
    echo "Usage: ./wda.sh <command> [args...]"
    echo "Commands: session, screenshot [path], tap <session> <x> <y>, type <session> 'text', swipe <session> <fx> <fy> <tx> <ty>, find <session> 'label', rect <session> <elem>, home, status"
    ;;
esac
