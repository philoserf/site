#!/bin/bash
# Content validation script for Hugo site
# Validates frontmatter completeness and consistency

set -e

echo "🔍 Validating content files..."

ERRORS=0
WARNINGS=0

# Required frontmatter fields
REQUIRED_FIELDS=("title" "date" "description" "tags" "publish")

# Check all markdown files in content/posts/
for file in content/posts/*.md; do
	if [ ! -f "$file" ]; then
		continue
	fi

	echo "Checking: $file"

	# Extract frontmatter (between --- markers)
	FRONTMATTER=$(awk '/^---$/{flag=!flag;next}flag' "$file")

	# Check for required fields
	for field in "${REQUIRED_FIELDS[@]}"; do
		if ! echo "$FRONTMATTER" | grep -q "^$field:"; then
			echo "  ❌ ERROR: Missing required field '$field' in $file"
			((ERRORS++))
		fi
	done

	# Check for lastmod field (warning only)
	if ! echo "$FRONTMATTER" | grep -q "^lastmod:"; then
		echo "  ⚠️  WARNING: Missing 'lastmod' field in $file"
		((WARNINGS++))
	fi

	# Check if tags field exists and has content
	# Count tag items (lines with "  - " after tags: line)
	TAG_COUNT=$(grep -A 10 "^tags:" <<<"$FRONTMATTER" | grep -c "^  - " || true)
	if [ "$TAG_COUNT" -eq 0 ]; then
		echo "  ⚠️  WARNING: No tags found in $file"
		((WARNINGS++))
	fi

	# Check date format (YYYY-MM-DD)
	DATE_VALUE=$(echo "$FRONTMATTER" | grep "^date:" | sed 's/date: *//')
	if [ -n "$DATE_VALUE" ]; then
		if ! echo "$DATE_VALUE" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}'; then
			echo "  ❌ ERROR: Invalid date format in $file (expected YYYY-MM-DD, got: $DATE_VALUE)"
			((ERRORS++))
		fi
	fi

	# Check for description length (at least 20 characters)
	DESCRIPTION=$(echo "$FRONTMATTER" | grep "^description:" | sed 's/description: *//')
	if [ -n "$DESCRIPTION" ]; then
		DESC_LENGTH=${#DESCRIPTION}
		if [ "$DESC_LENGTH" -lt 20 ]; then
			echo "  ⚠️  WARNING: Description is very short ($DESC_LENGTH chars) in $file"
			((WARNINGS++))
		fi
	fi

	# Check for orphaned 'category' field (should be removed)
	if echo "$FRONTMATTER" | grep -q "^category:"; then
		echo "  ⚠️  WARNING: Found 'category' field (not configured as taxonomy) in $file"
		((WARNINGS++))
	fi

	# Check tag format (lowercase with hyphens - skip /aliases or /paths)
	# Extract tag values (after "- ") and check for uppercase or spaces in the tag itself
	BAD_TAGS=$(echo "$FRONTMATTER" | grep "^  - " | grep -v "^  - /" | sed 's/^  - //' | grep -E "[A-Z ]" || true)
	if [ -n "$BAD_TAGS" ]; then
		echo "  ⚠️  WARNING: Tags contain uppercase or spaces in $file:"
		while IFS= read -r tag; do
			echo "      - $tag"
		done <<<"$BAD_TAGS"
		((WARNINGS++))
	fi
done

echo ""
echo "📊 Validation Summary"
echo "===================="
echo "Errors: $ERRORS"
echo "Warnings: $WARNINGS"
echo ""

if [ $ERRORS -gt 0 ]; then
	echo "❌ Validation failed with $ERRORS error(s)"
	exit 1
else
	echo "✅ All required validations passed!"
	if [ $WARNINGS -gt 0 ]; then
		echo "⚠️  There are $WARNINGS warning(s) to review"
	fi
	exit 0
fi
