#!/bin/bash

# Complete test suite for Pillar 2 email HTML size testing
# Tests both critical errors and generic errors with various configurations

echo "════════════════════════════════════════════════════════════════════"
echo "   Pillar 2 Email Renderer - HTML Size Testing"
echo "════════════════════════════════════════════════════════════════════"
echo ""

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Check if we're in the correct directory
if [ ! -f "conf/application.conf" ] || [ ! -d "app/preview" ]; then
    echo "❌ Error: This script must be run from the hmrc-email-renderer root directory"
    echo "   Current directory: $(pwd)"
    exit 1
fi

echo "⚙️  CONFIGURATION REQUIREMENT:"
echo "   This test requires: play.http.parser.maxMemoryBuffer = 1MB"
echo "   Location: conf/application.conf"
echo "   (Service must be restarted after config change)"
echo ""
echo "════════════════════════════════════════════════════════════════════"
echo ""

# ===========================================================================
# TEST 1: Critical Errors - All Error Codes
# ===========================================================================
echo "TEST 1: Critical Errors - All Error Codes"
echo "───────────────────────────────────────────────────────────────────"
echo "Data: app/preview/errorData.json (181 critical error codes)"
echo ""

JSON_PAYLOAD=$(jq -n \
  --arg referenceId "REF555666777" \
  --arg pillar2Id "XMPLR5556667777" \
  --arg submissionDate "15/10/2025" \
  --arg submissionTime "16:45" \
  --argjson errors "$(cat app/preview/errorData.json)" \
  '{
    parameters: {
      referenceId: $referenceId,
      pillar2Id: $pillar2Id,
      submissionDate: $submissionDate,
      submissionTime: $submissionTime,
      errors: ($errors | tostring)
    }
  }')

curl -X POST "http://localhost:8950/templates/pillar2_gir_submission_critical_errors" \
  -H "Content-Type: application/json" \
  -d "$JSON_PAYLOAD" -s | jq -r '.html' | base64 -d > /tmp/test1_critical_errors.html

if [ -s /tmp/test1_critical_errors.html ]; then
    SIZE1=$(wc -c < /tmp/test1_critical_errors.html | tr -d ' ')
    SIZE1_KB=$(awk "BEGIN {printf \"%.1f\", $SIZE1/1024}")
    echo "✅ HTML Size: ${SIZE1_KB} KB ($SIZE1 bytes)"
    echo "📁 Saved to: /tmp/test1_critical_errors.html"
else
    echo "❌ Test failed"
    SIZE1_KB="0"
fi
echo ""

# ===========================================================================
# TEST 2: Generic Errors - All Error Codes with 1 DocRefId Each
# ===========================================================================
echo "TEST 2: Generic Errors - All Error Codes (1 DocRefId Each)"
echo "───────────────────────────────────────────────────────────────────"
echo "Data: app/preview/errorDataGeneric.json (181 errors, 1 docRefId each)"
echo ""

JSON_PAYLOAD=$(jq -n \
  --arg referenceId "REF987654321" \
  --arg pillar2Id "XMPLR9876543210" \
  --arg submissionDate "15/10/2025" \
  --arg submissionTime "15:20" \
  --arg accountingPeriodStart "01/04/2024" \
  --arg accountingPeriodEnd "31/03/2025" \
  --argjson errors "$(cat app/preview/errorDataGeneric.json)" \
  '{
    parameters: {
      referenceId: $referenceId,
      pillar2Id: $pillar2Id,
      submissionDate: $submissionDate,
      submissionTime: $submissionTime,
      accountingPeriodStart: $accountingPeriodStart,
      accountingPeriodEnd: $accountingPeriodEnd,
      errors: ($errors | tostring)
    }
  }')

curl -X POST "http://localhost:8950/templates/pillar2_gir_submission_generic_errors" \
  -H "Content-Type: application/json" \
  -d "$JSON_PAYLOAD" -s | jq -r '.html' | base64 -d > /tmp/test2_generic_1docref.html

if [ -s /tmp/test2_generic_1docref.html ]; then
    SIZE2=$(wc -c < /tmp/test2_generic_1docref.html | tr -d ' ')
    SIZE2_KB=$(awk "BEGIN {printf \"%.1f\", $SIZE2/1024}")
    echo "✅ HTML Size: ${SIZE2_KB} KB ($SIZE2 bytes)"
    echo "📁 Saved to: /tmp/test2_generic_1docref.html"
else
    echo "❌ Test failed"
    SIZE2_KB="0"
fi
echo ""

# ===========================================================================
# TEST 3: Generic Errors - One Error with Many DocRefIds (500KB Target)
# ===========================================================================
echo "TEST 3: Generic Errors - One Error with 4,139 DocRefIds"
echo "───────────────────────────────────────────────────────────────────"
echo "Data: app/preview/errorDataGenericManyDocRefIds.json"
echo "      (1 error with 4,139 docRefIds, 120 chars each)"
echo ""

JSON_PAYLOAD=$(jq -n \
  --arg referenceId "REF987654321" \
  --arg pillar2Id "XMPLR9876543210" \
  --arg submissionDate "15/10/2025" \
  --arg submissionTime "15:20" \
  --arg accountingPeriodStart "01/04/2024" \
  --arg accountingPeriodEnd "31/03/2025" \
  --argjson errors "$(cat app/preview/errorDataGenericManyDocRefIds.json)" \
  '{
    parameters: {
      referenceId: $referenceId,
      pillar2Id: $pillar2Id,
      submissionDate: $submissionDate,
      submissionTime: $submissionTime,
      accountingPeriodStart: $accountingPeriodStart,
      accountingPeriodEnd: $accountingPeriodEnd,
      errors: ($errors | tostring)
    }
  }')

curl -X POST "http://localhost:8950/templates/pillar2_gir_submission_generic_errors" \
  -H "Content-Type: application/json" \
  -d "$JSON_PAYLOAD" -s | jq -r '.html' | base64 -d > /tmp/test3_generic_many_docrefs.html

if [ -s /tmp/test3_generic_many_docrefs.html ]; then
    SIZE3=$(wc -c < /tmp/test3_generic_many_docrefs.html | tr -d ' ')
    SIZE3_KB=$(awk "BEGIN {printf \"%.1f\", $SIZE3/1024}")
    echo "✅ HTML Size: ${SIZE3_KB} KB ($SIZE3 bytes)"
    echo "📁 Saved to: /tmp/test3_generic_many_docrefs.html"
    
    # Check if we hit 500KB
    HIT_500=$(awk "BEGIN {print ($SIZE3_KB >= 500) ? 1 : 0}")
    if [ "$HIT_500" -eq 1 ]; then
        echo "🎉 EXCEEDED 500KB TARGET!"
    else
        SHORTFALL=$(awk "BEGIN {printf \"%.1f\", 500 - $SIZE3_KB}")
        echo "📊 Status: ${SHORTFALL} KB away from 500KB target"
    fi
else
    echo "❌ Test failed"
    SIZE3_KB="0"
fi
echo ""

# ===========================================================================
# TEST 4: Calculations - Characters Needed for 500KB
# ===========================================================================
echo "TEST 4: Calculations - Characters Needed for 500KB"
echo "───────────────────────────────────────────────────────────────────"
echo ""

if [ "$SIZE3_KB" != "0" ]; then
    # Constants
    TOTAL_DOCREFS=4139
    CHARS_PER_DOCREF=120
    BYTES_PER_DOCREF=122  # 120 + 2 for ", "
    
    # Calculate KB per docRefId from Test 3 result
    KB_PER_DOCREF=$(awk "BEGIN {printf \"%.6f\", $SIZE3_KB / $TOTAL_DOCREFS}")
    
    # Calculate total characters (4139 docRefIds × 122 bytes)
    TOTAL_CHARS=$(awk "BEGIN {printf \"%.0f\", $TOTAL_DOCREFS * $BYTES_PER_DOCREF}")
    
    echo "📊 Analysis from Test 3:"
    echo "   • Tested with: 4,139 docRefIds"
    echo "   • Result: ${SIZE3_KB} KB HTML"
    echo "   • KB per docRefId: ${KB_PER_DOCREF} KB"
    echo ""
    echo "📈 For 500KB HTML:"
    echo "   • DocRefIds used: 4,139"
    echo "   • Total characters in docRefIds field: ${TOTAL_CHARS} chars"
    echo ""
    echo "💡 Formula:"
    echo "   4,139 docRefIds × 122 bytes each"
    echo "   = ${TOTAL_CHARS} characters"
    echo "   (120 chars per docRefId + 2 chars for ', ' separator)"
else
    echo "   ❌ Cannot calculate - Test 3 failed"
fi

echo ""
echo "════════════════════════════════════════════════════════════════════"
echo "   Summary"
echo "════════════════════════════════════════════════════════════════════"
echo ""
echo "TEST 1 - Critical Errors (181 codes):        ${SIZE1_KB} KB"
echo "TEST 2 - Generic Errors (181×1 docRefId):    ${SIZE2_KB} KB"
echo "TEST 3 - Generic Errors (1×4139 docRefIds):  ${SIZE3_KB} KB"
echo ""
echo "📁 HTML files saved to /tmp/"
echo "   • test1_critical_errors.html"
echo "   • test2_generic_1docref.html"
echo "   • test3_generic_many_docrefs.html"
echo ""
