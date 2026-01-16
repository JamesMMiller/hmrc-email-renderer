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

# Initialize variables
SIZE1_KB="0"
SIZE2_KB="0"
SIZE3_KB="0"
SIZE4_KB="0"

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
# TEST 4: Generic Errors - All 181 Errors with Many DocRefIds (UNDER 500KB Target)
# ===========================================================================
echo "TEST 4: Generic Errors - All 181 Errors with 18 DocRefIds Each"
echo "───────────────────────────────────────────────────────────────────"
echo "Data: app/preview/errorDataGenericAllErrorsManyDocRefIds.json"
echo "      (181 errors, 18 docRefIds each, testing UNDER 500KB limit)"
echo ""

if [ ! -f "app/preview/errorDataGenericAllErrorsManyDocRefIds.json" ]; then
    echo "⚠️  Warning: Test data file not found"
    echo "   Run the Python script to generate: errorDataGenericAllErrorsManyDocRefIds.json"
    SIZE4_KB="0"
else
    JSON_PAYLOAD=$(jq -n \
      --arg referenceId "REF111222333" \
      --arg pillar2Id "XMPLR1112223333" \
      --arg submissionDate "15/10/2025" \
      --arg submissionTime "14:30" \
      --arg accountingPeriodStart "01/04/2024" \
      --arg accountingPeriodEnd "31/03/2025" \
      --argjson errors "$(cat app/preview/errorDataGenericAllErrorsManyDocRefIds.json)" \
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
      -d "$JSON_PAYLOAD" -s | jq -r '.html' | base64 -d > /tmp/test4_generic_all_errors_many_docrefs.html

    if [ -s /tmp/test4_generic_all_errors_many_docrefs.html ]; then
        SIZE4=$(wc -c < /tmp/test4_generic_all_errors_many_docrefs.html | tr -d ' ')
        SIZE4_KB=$(awk "BEGIN {printf \"%.1f\", $SIZE4/1024}")
        TOTAL_DOCREFS=$(jq '[.[] | .count | tonumber] | add' app/preview/errorDataGenericAllErrorsManyDocRefIds.json)
        echo "✅ HTML Size: ${SIZE4_KB} KB ($SIZE4 bytes)"
        echo "📊 Total DocRefIds: $TOTAL_DOCREFS (18 per error × 181 errors)"
        echo "📁 Saved to: /tmp/test4_generic_all_errors_many_docrefs.html"
        
        # Check if we're UNDER 500KB (target for worst case scenario)
        UNDER_500=$(awk "BEGIN {print ($SIZE4_KB < 500) ? 1 : 0}")
        if [ "$UNDER_500" -eq 1 ]; then
            HEADROOM=$(awk "BEGIN {printf \"%.1f\", 500 - $SIZE4_KB}")
            echo "✅ SUCCESS: Under 500KB limit with ${HEADROOM} KB headroom"
        else
            EXCEEDED=$(awk "BEGIN {printf \"%.1f\", $SIZE4_KB - 500}")
            echo "⚠️  WARNING: Exceeded 500KB limit by ${EXCEEDED} KB"
            echo "   Consider reducing docRefIds per error"
        fi
    else
        echo "❌ Test failed"
        SIZE4_KB="0"
    fi
fi
echo ""

# ===========================================================================
# TEST 5: Calculations - Characters Needed for 500KB
# ===========================================================================
echo "TEST 5: Calculations - Characters Needed for 500KB"
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
    
    echo "📊 Analysis from Test 3 (1 error with many docRefIds):"
    echo "   • Tested with: 4,139 docRefIds"
    echo "   • Result: ${SIZE3_KB} KB HTML"
    echo "   • KB per docRefId: ${KB_PER_DOCREF} KB"
    echo ""
    
    # Calculate Test 4 totals for worst case analysis
    TOTAL_DOCREFS_4=$(jq '[.[] | .count | tonumber] | add' app/preview/errorDataGenericAllErrorsManyDocRefIds.json 2>/dev/null || echo "0")
    
    if [ "$SIZE4_KB" != "0" ] && [ "$TOTAL_DOCREFS_4" != "0" ]; then
        KB_PER_DOCREF_4=$(awk "BEGIN {printf \"%.6f\", $SIZE4_KB / $TOTAL_DOCREFS_4}")
        echo "📊 Analysis from Test 4 (181 errors with docRefIds):"
        echo "   • Tested with: $TOTAL_DOCREFS_4 docRefIds (181 errors × 18 docRefIds each)"
        echo "   • Result: ${SIZE4_KB} KB HTML (target: UNDER 500KB)"
        echo "   • KB per docRefId: ${KB_PER_DOCREF_4} KB"
        echo ""
    fi
    
    echo "📈 For 500KB HTML:"
    echo ""
    echo "   Single Error Approach (Test 3):"
    echo "   • DocRefIds: 4,139"
    echo "   • Total characters in docRefIds field: ${TOTAL_CHARS} chars"
    echo "   • Formula: 4,139 docRefIds × 122 bytes each = ${TOTAL_CHARS} characters"
    echo "             (120 chars per docRefId + 2 chars for ', ' separator)"
    echo ""
    
    if [ "$TOTAL_DOCREFS_4" != "0" ]; then
        # Calculate total characters for Test 4 (worst case)
        TOTAL_CHARS_4=$(awk "BEGIN {printf \"%.0f\", $TOTAL_DOCREFS_4 * $BYTES_PER_DOCREF}")
        echo "   ⚠️  WORST CASE: All 181 Errors Approach (Test 4):"
        echo "   • DocRefIds: $TOTAL_DOCREFS_4 (181 errors × 18 docRefIds each)"
        echo "   • Total characters in docRefIds field: ${TOTAL_CHARS_4} chars"
        echo "   • Formula: $TOTAL_DOCREFS_4 docRefIds × 122 bytes each = ${TOTAL_CHARS_4} characters"
        echo "             (120 chars per docRefId + 2 chars for ', ' separator)"
        if [ "$SIZE4_KB" != "0" ]; then
            UNDER_CHECK=$(awk "BEGIN {print ($SIZE4_KB < 500) ? 1 : 0}")
            if [ "$UNDER_CHECK" -eq 1 ]; then
                HEADROOM=$(awk "BEGIN {printf \"%.1f\", 500 - $SIZE4_KB}")
                echo "   • HTML Size: ${SIZE4_KB} KB ✅ (UNDER 500KB limit with ${HEADROOM} KB headroom)"
            else
                EXCEEDED=$(awk "BEGIN {printf \"%.1f\", $SIZE4_KB - 500}")
                echo "   • HTML Size: ${SIZE4_KB} KB ⚠️ (EXCEEDED 500KB by ${EXCEEDED} KB)"
            fi
            echo "   • Note: Includes HTML overhead for 181 table rows (worst case scenario)"
            echo ""
            echo "💡 Summary:"
            echo "   • Best case (single error): ${TOTAL_CHARS} chars → ${SIZE3_KB} KB HTML"
            echo "   • Worst case (all errors): ${TOTAL_CHARS_4} chars → ${SIZE4_KB} KB HTML (target: <500KB)"
        else
            echo "   • HTML Size: Test 4 not completed"
            echo "   • Expected: ~490 KB (UNDER 500KB limit with all 181 error rows)"
            echo "   • Note: Includes HTML overhead for 181 table rows (worst case scenario)"
            echo ""
            echo "💡 Summary:"
            echo "   • Best case (single error): ${TOTAL_CHARS} chars → ${SIZE3_KB} KB HTML"
            echo "   • Worst case (all errors): ${TOTAL_CHARS_4} chars → Expected ~490 KB HTML (target: <500KB)"
        fi
    else
        echo "   ⚠️  WORST CASE: All 181 Errors Approach (Test 4):"
        echo "   • Test 4 data not available for worst case calculation"
    fi
else
    echo "   ❌ Cannot calculate - Test 3 failed"
fi

echo ""
echo "════════════════════════════════════════════════════════════════════"
echo "   Summary"
echo "════════════════════════════════════════════════════════════════════"
echo ""
echo "TEST 1 - Critical Errors (181 codes):                    ${SIZE1_KB} KB"
echo "TEST 2 - Generic Errors (181×1 docRefId):                 ${SIZE2_KB} KB"
echo "TEST 3 - Generic Errors (1×4139 docRefIds):               ${SIZE3_KB} KB"
echo "TEST 4 - Generic Errors (181×18 docRefIds):               ${SIZE4_KB} KB (target: <500KB)"
echo ""
echo "📁 HTML files saved to /tmp/"
echo "   • test1_critical_errors.html"
echo "   • test2_generic_1docref.html"
echo "   • test3_generic_many_docrefs.html"
echo "   • test4_generic_all_errors_many_docrefs.html"
echo ""
