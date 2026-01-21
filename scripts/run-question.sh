#!/bin/bash

# CKS Simulator - Inspired by killer.sh
# Run practice questions for CKS exam preparation

set -e

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║                    CKS Exam Simulator 2026                       ║"
    echo "║            Certified Kubernetes Security Specialist              ║"
    echo "╚══════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_usage() {
    echo "Usage: $0 <question> [command]"
    echo ""
    echo "Commands:"
    echo "  list              - List all available questions"
    echo "  exam              - Start a full exam simulation (2 hours)"
    echo ""
    echo "Question Commands (default: setup):"
    echo "  setup             - Setup environment for question"
    echo "  verify            - Verify your solution for question"
    echo "  solution          - Show solution for question"
    echo "  reset             - Reset environment for question"
    echo "  question          - Display question text only"
    echo ""
    echo "Examples:"
    echo "  $0 Question-06-AppArmor          - Setup question 6 (default)"
    echo "  $0 Question-06-AppArmor verify   - Verify question 6 solution"
    echo "  $0 6 solution                    - Show solution for question 6"
    echo "  $0 list                          - List all questions"
}

get_question_dir() {
    local input=$1

    # If input looks like a directory name (Question-XX-Name), extract the number
    if [[ $input =~ ^Question-([0-9]+) ]]; then
        local num="${BASH_REMATCH[1]}"
    else
        local num=$input
    fi

    # Pad the number to 2 digits
    local padded_num=$(printf '%02d' $num 2>/dev/null)

    # If printf failed (input wasn't a number), try to find by exact directory name
    if [ $? -ne 0 ]; then
        local dir=$(find $BASE_DIR -maxdepth 1 -type d -name "$input" 2>/dev/null | head -1)
    else
        local dir=$(find $BASE_DIR -maxdepth 1 -type d -name "Question-${padded_num}-*" 2>/dev/null | head -1)
    fi

    echo "$dir"
}

list_questions() {
    print_header
    echo -e "${YELLOW}Available Questions:${NC}"
    echo ""

    for dir in $BASE_DIR/Question-*; do
        if [ -d "$dir" ]; then
            local name=$(basename "$dir")
            local num=$(echo "$name" | sed 's/Question-\([0-9]*\)-.*/\1/')
            local title=$(echo "$name" | sed 's/Question-[0-9]*-//' | tr '-' ' ')

            if [ -f "$dir/question.txt" ]; then
                local weight=$(grep -i "weight:" "$dir/question.txt" 2>/dev/null | head -1 | cut -d':' -f2 | tr -d ' ')
                local domain=$(grep -i "domain:" "$dir/question.txt" 2>/dev/null | head -1 | cut -d':' -f2-)
                echo -e "  ${GREEN}Q$num${NC} - $title"
                echo -e "       Weight: ${YELLOW}${weight:-N/A}%${NC} | Domain: ${BLUE}${domain:-N/A}${NC}"
            else
                echo -e "  ${GREEN}Q$num${NC} - $title"
            fi
        fi
    done
    echo ""
}

run_setup() {
    local question_id=$1
    local dir=$(get_question_dir $question_id)
    local question_name=$(basename "$dir")

    if [ -z "$dir" ] || [ ! -d "$dir" ]; then
        echo -e "${RED}Error: Question '$question_id' not found${NC}"
        exit 1
    fi

    if [ ! -f "$dir/setup.sh" ]; then
        echo -e "${RED}Error: setup.sh not found for question '$question_id'${NC}"
        exit 1
    fi

    print_header
    echo -e "${YELLOW}Setting up $question_name...${NC}"
    echo ""

    bash "$dir/setup.sh"

    echo ""
    echo -e "${GREEN}✓ Setup complete!${NC}"
    echo ""
    echo -e "${CYAN}Question:${NC}"
    echo "─────────────────────────────────────────────────────────────────────"
    cat "$dir/question.txt"
    echo "─────────────────────────────────────────────────────────────────────"
    echo ""
    echo -e "Run ${YELLOW}./scripts/run-question.sh $question_id verify${NC} when you're done."
}

run_verify() {
    local question_id=$1
    local dir=$(get_question_dir $question_id)
    local question_name=$(basename "$dir")

    if [ -z "$dir" ] || [ ! -d "$dir" ]; then
        echo -e "${RED}Error: Question '$question_id' not found${NC}"
        exit 1
    fi

    if [ ! -f "$dir/verify.sh" ]; then
        echo -e "${RED}Error: verify.sh not found for question '$question_id'${NC}"
        exit 1
    fi

    print_header
    echo -e "${YELLOW}Verifying $question_name...${NC}"
    echo ""

    if bash "$dir/verify.sh"; then
        echo ""
        echo -e "${GREEN}══════════════════════════════════════════════════════════════════${NC}"
        echo -e "${GREEN}                    ✓ $question_name: PASSED!                      ${NC}"
        echo -e "${GREEN}══════════════════════════════════════════════════════════════════${NC}"
    else
        echo ""
        echo -e "${RED}══════════════════════════════════════════════════════════════════${NC}"
        echo -e "${RED}                    ✗ $question_name: FAILED                       ${NC}"
        echo -e "${RED}══════════════════════════════════════════════════════════════════${NC}"
        echo ""
        echo -e "Run ${YELLOW}./scripts/run-question.sh $question_id solution${NC} to see the solution."
    fi
}

run_solution() {
    local question_id=$1
    local dir=$(get_question_dir $question_id)
    local question_name=$(basename "$dir")

    if [ -z "$dir" ] || [ ! -d "$dir" ]; then
        echo -e "${RED}Error: Question '$question_id' not found${NC}"
        exit 1
    fi

    if [ ! -f "$dir/solution.sh" ]; then
        echo -e "${RED}Error: solution.sh not found for question '$question_id'${NC}"
        exit 1
    fi

    print_header
    echo -e "${YELLOW}Solution for $question_name:${NC}"
    echo ""

    bash "$dir/solution.sh"
}

run_reset() {
    local question_id=$1
    local dir=$(get_question_dir $question_id)
    local question_name=$(basename "$dir")

    if [ -z "$dir" ] || [ ! -d "$dir" ]; then
        echo -e "${RED}Error: Question '$question_id' not found${NC}"
        exit 1
    fi

    if [ ! -f "$dir/reset.sh" ]; then
        echo -e "${RED}Error: reset.sh not found for question '$question_id'${NC}"
        exit 1
    fi

    print_header
    echo -e "${YELLOW}Resetting $question_name...${NC}"
    echo ""

    bash "$dir/reset.sh"

    echo ""
    echo -e "${GREEN}✓ Reset complete!${NC}"
}

show_question() {
    local question_id=$1
    local dir=$(get_question_dir $question_id)
    local question_name=$(basename "$dir")

    if [ -z "$dir" ] || [ ! -d "$dir" ]; then
        echo -e "${RED}Error: Question '$question_id' not found${NC}"
        exit 1
    fi

    if [ ! -f "$dir/question.txt" ]; then
        echo -e "${RED}Error: question.txt not found for question '$question_id'${NC}"
        exit 1
    fi

    print_header
    echo -e "${CYAN}$question_name:${NC}"
    echo "─────────────────────────────────────────────────────────────────────"
    cat "$dir/question.txt"
    echo "─────────────────────────────────────────────────────────────────────"
}

run_exam() {
    print_header
    echo -e "${CYAN}Starting CKS Exam Simulation${NC}"
    echo -e "${YELLOW}Time Limit: 2 hours${NC}"
    echo -e "${YELLOW}Questions: 15-20 tasks${NC}"
    echo -e "${YELLOW}Passing Score: 67%${NC}"
    echo ""
    echo -e "${RED}WARNING: This will setup all questions and start a 2-hour timer!${NC}"
    read -p "Press ENTER to start or CTRL+C to cancel..."

    echo ""
    echo -e "${GREEN}Setting up all questions...${NC}"

    for dir in $BASE_DIR/Question-*; do
        if [ -d "$dir" ] && [ -f "$dir/setup.sh" ]; then
            local name=$(basename "$dir")
            echo -n "  Setting up $name... "
            bash "$dir/setup.sh" > /dev/null 2>&1 && echo -e "${GREEN}✓${NC}" || echo -e "${RED}✗${NC}"
        fi
    done

    echo ""
    echo -e "${GREEN}All questions ready!${NC}"
    echo ""
    echo -e "${CYAN}Your 2-hour exam starts NOW!${NC}"
    echo -e "${YELLOW}Good luck!${NC}"
    echo ""

    # Start timer in background
    (sleep 7200 && echo -e "\n${RED}TIME'S UP! Exam ended.${NC}") &

    list_questions
}

# Main
case "${1:-}" in
    list)
        list_questions
        ;;
    exam)
        run_exam
        ;;
    "")
        print_header
        print_usage
        ;;
    *)
        # First argument is the question identifier
        QUESTION_ID="$1"
        COMMAND="${2:-setup}"  # Default to setup if no command specified

        case "$COMMAND" in
            setup)
                run_setup "$QUESTION_ID"
                ;;
            verify)
                run_verify "$QUESTION_ID"
                ;;
            solution)
                run_solution "$QUESTION_ID"
                ;;
            reset)
                run_reset "$QUESTION_ID"
                ;;
            question)
                show_question "$QUESTION_ID"
                ;;
            *)
                echo -e "${RED}Error: Unknown command '$COMMAND'${NC}"
                echo -e "Valid commands: setup, verify, solution, reset, question"
                exit 1
                ;;
        esac
        ;;
esac
