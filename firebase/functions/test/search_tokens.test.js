const { generateSearchTokens } = require("../utils/search-tokens");

describe("generateSearchTokens", () => {
  test("generates all substrings of a single word", () => {
    const tokens = generateSearchTokens("jshew");
    // 5-char word → 10 tokens
    expect(tokens).toContain("js");
    expect(tokens).toContain("jsh");
    expect(tokens).toContain("jshe");
    expect(tokens).toContain("jshew");
    expect(tokens).toContain("sh");
    expect(tokens).toContain("she");
    expect(tokens).toContain("shew");
    expect(tokens).toContain("he");
    expect(tokens).toContain("hew");
    expect(tokens).toContain("ew");
    expect(tokens).toHaveLength(10);
  });

  test("handles multi-word display name", () => {
    const tokens = generateSearchTokens("John Doe");
    expect(tokens).toContain("jo");
    expect(tokens).toContain("john");
    expect(tokens).toContain("oh");
    expect(tokens).toContain("do");
    expect(tokens).toContain("doe");
    expect(tokens).toContain("oe");
  });

  test("includes tokens from firstName and lastName", () => {
    const tokens = generateSearchTokens("jshew", "Jay", "Shew");
    expect(tokens).toContain("ja");
    expect(tokens).toContain("jay");
    expect(tokens).toContain("ay");
    expect(tokens).toContain("sh");
    expect(tokens).toContain("shew");
  });

  test("deduplicates tokens across name fields", () => {
    const tokens = generateSearchTokens("shew", "Shew");
    const unique = new Set(tokens);
    expect(tokens.length).toBe(unique.size);
  });

  test("returns sorted tokens", () => {
    const tokens = generateSearchTokens("zab");
    const sorted = [...tokens].sort();
    expect(tokens).toEqual(sorted);
  });

  test("returns empty array for empty input", () => {
    const tokens = generateSearchTokens("");
    expect(tokens).toHaveLength(0);
  });

  test("returns empty array for single character", () => {
    const tokens = generateSearchTokens("A");
    expect(tokens).toHaveLength(0);
  });

  test("returns empty array for null/undefined", () => {
    expect(generateSearchTokens(null)).toHaveLength(0);
    expect(generateSearchTokens(undefined)).toHaveLength(0);
  });

  test("is case insensitive", () => {
    const upper = generateSearchTokens("JOHN");
    const lower = generateSearchTokens("john");
    expect(upper).toEqual(lower);
  });

  test("respects custom minLength", () => {
    const tokens = generateSearchTokens("abc", null, null, 3);
    expect(tokens).toEqual(["abc"]);
  });

  test("substring search finds partial matches", () => {
    const userTokens = generateSearchTokens("jshew");
    expect(userTokens).toContain("shew");
  });
});
