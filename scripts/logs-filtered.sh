#!/bin/bash

# Script to view docker-compose logs with common error filters applied

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default parameters
FOLLOW=false
SERVICE=""
TAIL_LINES=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--follow)
            FOLLOW=true
            shift
            ;;
        -t|--tail)
            TAIL_LINES="--tail $2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS] [SERVICE]"
            echo ""
            echo "Options:"
            echo "  -f, --follow     Follow log output"
            echo "  -t, --tail NUM   Number of lines to show from the end of the logs"
            echo "  -h, --help       Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                    # Show all logs (filtered)"
            echo "  $0 -f                 # Follow all logs (filtered)"
            echo "  $0 node-exporter      # Show node-exporter logs (filtered)"
            echo "  $0 -f -t 100 grafana  # Follow last 100 lines of grafana logs"
            exit 0
            ;;
        *)
            SERVICE=$1
            shift
            ;;
    esac
done

# Build the docker-compose command
CMD="docker-compose logs"
if [ "$FOLLOW" = true ]; then
    CMD="$CMD -f"
fi
if [ -n "$TAIL_LINES" ]; then
    CMD="$CMD $TAIL_LINES"
fi
if [ -n "$SERVICE" ]; then
    CMD="$CMD $SERVICE"
fi

# Define filters for known non-critical errors
FILTERS=(
    # Node Exporter connection reset errors
    "error encoding and sending metric family.*connection reset by peer"
    # Add more filters here as needed
    # Example: "another known error pattern"
)

# Build grep filter command
GREP_FILTERS=""
for filter in "${FILTERS[@]}"; do
    if [ -z "$GREP_FILTERS" ]; then
        GREP_FILTERS="grep -v \"$filter\""
    else
        GREP_FILTERS="$GREP_FILTERS | grep -v \"$filter\""
    fi
done

# Show what's being filtered
echo -e "${YELLOW}Filtering out known non-critical errors:${NC}"
for filter in "${FILTERS[@]}"; do
    echo -e "  ${RED}✗${NC} $filter"
done
echo ""

# Execute the command with filters
eval "$CMD | $GREP_FILTERS"