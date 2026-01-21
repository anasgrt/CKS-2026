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
    echo "Usage: $0 <command> [question-number]"
    echo ""
    echo "Commands:"
    echo "  list              - List all available questions"
    echo "  setup <N>         - Setup environment for question N"
    echo "  verify <N>        - Verify your solution for question N"
    echo "  solution <N>      - Show solution for question N"
    echo "  reset <N>         - Reset environment for question N"
    echo "  question <N>      - Display question N"
    echo "  exam              - Start a full exam simulation (2 hours)"
    echo ""
    echo "Example:"
    echo "  $0 setup 1        - Setup question 1"
    echo "  $0 verify 1       - Check if question 1 is solved correctly"
}

get_question_dir() {
    local num=$1
    local padded_num=$(printf '%02d' $num)
    local dir=$(find $BASE_DIR -maxdepth 1 -type d -name "Question-${padded_num}-*" 2>/dev/null | head -1)
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
    local num=$1
    local dir=$(get_question_dir $num)

    if [ -z "$dir" ] || [ ! -d "$dir" ]; then
        echo -e "${RED}Error: Question $num not found${NC}"
        exit 1
    fi

    if [ ! -f "$dir/setup.sh" ]; then
        echo -e "${RED}Error: setup.sh not found for question $num${NC}"
        exit 1
    fi

    print_header
    echo -e "${YELLOW}Setting up Question $num...${NC}"
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
    echo -e "Run ${YELLOW}./scripts/run-question.sh verify $num${NC} when you're done."
}

run_verify() {
    local num=$1
    local dir=$(get_question_dir $num)

    if [ -z "$dir" ] || [ ! -d "$dir" ]; then
        echo -e "${RED}Error: Question $num not found${NC}"
        exit 1
    fi

    if [ ! -f "$dir/verify.sh" ]; then
        echo -e "${RED}Error: verify.sh not found for question $num${NC}"
        exit 1
    fi

    print_header
    echo -e "${YELLOW}Verifying Question $num...${NC}"
    echo ""

    if bash "$dir/verify.sh"; then
        echo ""
        echo -e "${GREEN}══════════════════════════════════════════════════════════════════${NC}"
        echo -e "${GREEN}                    ✓ QUESTION $num: PASSED!                      ${NC}"
        echo -e "${GREEN}══════════════════════════════════════════════════════════════════${NC}"
    else
        echo ""
        echo -e "${RED}══════════════════════════════════════════════════════════════════${NC}"
        echo -e "${RED}                    ✗ QUESTION $num: FAILED                       ${NC}"
        echo -e "${RED}══════════════════════════════════════════════════════════════════${NC}"
        echo ""
        echo -e "Run ${YELLOW}./scripts/run-question.sh solution $num${NC} to see the solution."
    fi
}

run_solution() {
    local num=$1
    local dir=$(get_question_dir $num)

    if [ -z "$dir" ] || [ ! -d "$dir" ]; then
        echo -e "${RED}Error: Question $num not found${NC}"
        exit 1
    fi

    if [ ! -f "$dir/solution.sh" ]; then
        echo -e "${RED}Error: solution.sh not found for question $num${NC}"
        exit 1
    fi

    print_header
    echo -e "${YELLOW}Solution for Question $num:${NC}"
    echo ""

    bash "$dir/solution.sh"
}

run_reset() {
    local num=$1
    local dir=$(get_question_dir $num)

    if [ -z "$dir" ] || [ ! -d "$dir" ]; then
        echo -e "${RED}Error: Question $num not found${NC}"
        exit 1
    fi

    if [ ! -f "$dir/reset.sh" ]; then
        echo -e "${RED}Error: reset.sh not found for question $num${NC}"
        exit 1
    fi

    print_header
    echo -e "${YELLOW}Resetting Question $num...${NC}"
    echo ""

    bash "$dir/reset.sh"

    echo ""
    echo -e "${GREEN}✓ Reset complete!${NC}"
}

show_question() {
    local num=$1
    local dir=$(get_question_dir $num)

    if [ -z "$dir" ] || [ ! -d "$dir" ]; then
        echo -e "${RED}Error: Question $num not found${NC}"
        exit 1
    fi

    if [ ! -f "$dir/question.txt" ]; then
        echo -e "${RED}Error: question.txt not found for question $num${NC}"
        exit 1
    fi

    print_header
    echo -e "${CYAN}Question $num:${NC}"
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
    setup)
        if [ -z "${2:-}" ]; then
            echo -e "${RED}Error: Please specify a question number${NC}"
            print_usage
            exit 1
        fi
        run_setup $2
        ;;
    verify)
        if [ -z "${2:-}" ]; then
            echo -e "${RED}Error: Please specify a question number${NC}"
            print_usage
            exit 1
        fi
        run_verify $2
        ;;
    solution)
        if [ -z "${2:-}" ]; then
            echo -e "${RED}Error: Please specify a question number${NC}"
            print_usage
            exit 1
        fi
        run_solution $2
        ;;
    reset)
        if [ -z "${2:-}" ]; then
            echo -e "${RED}Error: Please specify a question number${NC}"
            print_usage
            exit 1
        fi
        run_reset $2
        ;;
    question)
        if [ -z "${2:-}" ]; then
            echo -e "${RED}Error: Please specify a question number${NC}"
            print_usage
            exit 1
        fi
        show_question $2
        ;;
    exam)
        run_exam
        ;;
    *)
        print_header
        print_usage
        ;;
esac
