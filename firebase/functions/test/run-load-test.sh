#!/bin/bash

###############################################################################
# Load Test Runner Script
# Session 13: Push Notifications Trust System
#
# Usage:
#   ./run-load-test.sh [options]
#
# Options:
#   --small        Run small test (50 games, 30 min)
#   --medium       Run medium test (200 games, 1 hour)
#   --full         Run full test (500 games, 2 hours) [default]
#   --cleanup      Only run cleanup (remove test data)
#   --help         Show this help message
###############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
FUNCTIONS_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"

# Default test size
TEST_SIZE="full"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --small)
      TEST_SIZE="small"
      shift
      ;;
    --medium)
      TEST_SIZE="medium"
      shift
      ;;
    --full)
      TEST_SIZE="full"
      shift
      ;;
    --cleanup)
      TEST_SIZE="cleanup"
      shift
      ;;
    --help)
      head -n 20 "$0" | tail -n 15
      exit 0
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  PUSH NOTIFICATIONS TRUST SYSTEM - LOAD TEST                   ║${NC}"
echo -e "${BLUE}║  Session 13: Saturday Morning Peak Validation                  ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Function to check prerequisites
check_prerequisites() {
  echo -e "${YELLOW}Checking prerequisites...${NC}"

  # Check Node.js
  if ! command -v node &> /dev/null; then
    echo -e "${RED}✗ Node.js not found. Please install Node.js 20+${NC}"
    exit 1
  fi

  NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
  if [ "$NODE_VERSION" -lt 18 ]; then
    echo -e "${RED}✗ Node.js version too old. Please upgrade to Node.js 18+${NC}"
    exit 1
  fi
  echo -e "${GREEN}✓ Node.js $(node -v)${NC}"

  # Check npm dependencies
  if [ ! -d "$FUNCTIONS_DIR/node_modules" ]; then
    echo -e "${YELLOW}Installing dependencies...${NC}"
    cd "$FUNCTIONS_DIR"
    npm install
  fi
  echo -e "${GREEN}✓ Dependencies installed${NC}"

  # Check Firebase credentials
  if [ -z "$GOOGLE_APPLICATION_CREDENTIALS" ] && [ ! -f "$HOME/.config/gcloud/application_default_credentials.json" ]; then
    echo -e "${YELLOW}⚠ Warning: No Firebase credentials found${NC}"
    echo -e "${YELLOW}  Set GOOGLE_APPLICATION_CREDENTIALS or run 'firebase login'${NC}"
  else
    echo -e "${GREEN}✓ Firebase credentials found${NC}"
  fi

  echo ""
}

# Function to configure test size
configure_test() {
  case $TEST_SIZE in
    small)
      echo -e "${BLUE}Test Configuration: SMALL${NC}"
      echo "  Games: 50"
      echo "  Duration: 30 minutes"
      echo "  Users: ~100"
      echo ""

      # Modify CONFIG in load-test.js
      sed -i.bak 's/TOTAL_GAMES: 500/TOTAL_GAMES: 50/' "$SCRIPT_DIR/load-test.js"
      sed -i.bak 's/TEST_DURATION_HOURS: 2/TEST_DURATION_HOURS: 0.5/' "$SCRIPT_DIR/load-test.js"
      ;;

    medium)
      echo -e "${BLUE}Test Configuration: MEDIUM${NC}"
      echo "  Games: 200"
      echo "  Duration: 1 hour"
      echo "  Users: ~400"
      echo ""

      sed -i.bak 's/TOTAL_GAMES: 500/TOTAL_GAMES: 200/' "$SCRIPT_DIR/load-test.js"
      sed -i.bak 's/TEST_DURATION_HOURS: 2/TEST_DURATION_HOURS: 1/' "$SCRIPT_DIR/load-test.js"
      ;;

    full)
      echo -e "${BLUE}Test Configuration: FULL (Production Scenario)${NC}"
      echo "  Games: 500"
      echo "  Duration: 2 hours"
      echo "  Users: ~1,500"
      echo ""
      # No changes needed - defaults to full
      ;;

    cleanup)
      echo -e "${YELLOW}Cleanup Mode: Removing test data only${NC}"
      echo ""
      ;;
  esac
}

# Function to restore original config
restore_config() {
  if [ -f "$SCRIPT_DIR/load-test.js.bak" ]; then
    mv "$SCRIPT_DIR/load-test.js.bak" "$SCRIPT_DIR/load-test.js"
  fi
}

# Trap to restore config on exit
trap restore_config EXIT

# Function to run cleanup only
run_cleanup() {
  echo -e "${YELLOW}Running cleanup...${NC}"
  echo ""

  cd "$FUNCTIONS_DIR"

  # Create a minimal cleanup script
  node -e "
    const admin = require('firebase-admin');
    if (!admin.apps.length) admin.initializeApp();
    const db = admin.firestore();

    const TEST_PREFIX = 'LOADTEST_';
    const collections = [
      'users', 'games', 'round_jobs', 'round_records',
      'pair_ratings', 'scheduledNotifications', 'notificationLog',
      'cancellation_records', 'strikes'
    ];

    async function cleanup() {
      console.log('Cleaning up test data...');
      let totalDeleted = 0;

      for (const col of collections) {
        const snapshot = await db.collection(col).where('test_marker', '==', TEST_PREFIX).get();
        if (snapshot.empty) continue;

        const batchSize = 500;
        for (let i = 0; i < snapshot.docs.length; i += batchSize) {
          const batch = db.batch();
          snapshot.docs.slice(i, i + batchSize).forEach(doc => batch.delete(doc.ref));
          await batch.commit();
          totalDeleted += Math.min(batchSize, snapshot.docs.length - i);
        }

        console.log(\`  Deleted \${snapshot.docs.length} from \${col}\`);
      }

      // Clean users
      const users = await db.collection('users')
        .where(admin.firestore.FieldPath.documentId(), '>=', TEST_PREFIX)
        .where(admin.firestore.FieldPath.documentId(), '<', TEST_PREFIX + '\uf8ff')
        .get();

      for (const userDoc of users.docs) {
        const tokens = await userDoc.ref.collection('fcm_tokens').get();
        const batch = db.batch();
        tokens.docs.forEach(t => batch.delete(t.ref));
        batch.delete(userDoc.ref);
        await batch.commit();
        totalDeleted++;
      }

      console.log(\`✓ Cleanup complete (\${totalDeleted} total documents)\`);
      process.exit(0);
    }

    cleanup().catch(err => {
      console.error('Cleanup failed:', err);
      process.exit(1);
    });
  "

  exit $?
}

# Main execution
main() {
  check_prerequisites

  if [ "$TEST_SIZE" == "cleanup" ]; then
    run_cleanup
    exit 0
  fi

  configure_test

  echo -e "${YELLOW}⚠ WARNING: This test will create real Firestore documents and trigger Cloud Functions${NC}"
  echo -e "${YELLOW}  Estimated cost: \$0.15 - \$0.30${NC}"
  echo -e "${YELLOW}  Duration: $([ "$TEST_SIZE" == "small" ] && echo "~15 min" || [ "$TEST_SIZE" == "medium" ] && echo "~45 min" || echo "~2.5 hours")${NC}"
  echo ""

  read -p "Continue? (y/N) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}Aborted${NC}"
    exit 1
  fi

  echo ""
  echo -e "${GREEN}Starting load test...${NC}"
  echo ""

  cd "$FUNCTIONS_DIR"

  # Run with increased memory
  START_TIME=$(date +%s)

  if node --max-old-space-size=4096 test/load-test.js; then
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))

    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  LOAD TEST PASSED ✓                                            ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN}Duration: $((DURATION / 60)) minutes $((DURATION % 60)) seconds${NC}"
    echo -e "${GREEN}Report: test/load-test-report.json${NC}"
    echo ""

    # Show quick summary
    if [ -f "$SCRIPT_DIR/load-test-report.json" ]; then
      echo -e "${BLUE}Quick Summary:${NC}"
      node -e "
        const report = require('./test/load-test-report.json');
        console.log(\`  P50: \${report.summary.latency.P50}ms\`);
        console.log(\`  P95: \${report.summary.latency.P95}ms\`);
        console.log(\`  P99: \${report.summary.latency.P99}ms\`);
        console.log(\`  Error Rate: \${(report.summary.errorRate * 100).toFixed(2)}%\`);
        console.log(\`  Total Cost: \$\${report.summary.costs.totalCost.toFixed(4)}\`);
      "
      echo ""
    fi

    exit 0
  else
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))

    echo ""
    echo -e "${RED}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║  LOAD TEST FAILED ✗                                            ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${RED}Duration: $((DURATION / 60)) minutes $((DURATION % 60)) seconds${NC}"
    echo -e "${YELLOW}Check test/load-test-report.json for details${NC}"
    echo ""

    exit 1
  fi
}

# Run main function
main
