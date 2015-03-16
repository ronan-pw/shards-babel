local babel = require "module"
local dict = babel.dictionary
local lang = babel.language
local words = babel.words
local text = babel.text

local orig = "[yells] Goodbye, [pauses] cruel multiverse! / plz DM kill me"
local strings = { "[yells]", " ", "Goodbye", ", ", "[pauses]", " ", "cruel", " ", "multiverse", "! ", "/ plz DM kill me" }

describe("words", function()
  it("can break down text into strings of words and non-words", function()
    assert.are.same(strings, words.to_strings(orig))
  end)
  describe("complexity", function()
    it("only works on words", function()
      assert.are.equal(nil, words.skill_required(""))
      assert.are.equal(nil, words.skill_required(5))
    end)
    it("is a function of word length", function()
      assert.are.equal(5, words.skill_required("a"))
      assert.are.equal(25, words.skill_required("babel"))
      assert.are.equal(100, words.skill_required("pneumonoultramicroscopicsilicovolcanoconiosis"))
    end)
  end)
  it("can be translated when skill >= skill_required", function()
    assert.are.equal(false, words.understands("",5))
    assert.are.equal(true, words.understands("a",5))
    assert.are.equal(false, words.understands("to",5))
  end)
  it("can be detected", function()
    assert.are.equal(false, words.is_word(""))
    assert.are.equal(true, words.is_word("test"))
    assert.are.equal(false, words.is_word("1234"))
    assert.are.equal(false, words.is_word("1234!"))
    assert.are.equal(false, words.is_word("..."))
  end)
end)

local english_to_french
local blank_dict
local english_to_french_substrings = {--[[
  
  goodbye = "au revoir",
  bye = "au revoir",
  cruel = "sadique",
  multi = "beaucoup"
]]}
english_to_french_substrings["the "] = "l'"
describe("dictionaries", function()
  it("should be creatable", function()
    blank_dict = dict.new({})
    english_to_french = dict.new({
      multi = "beaucoup-",
      e = "é"
    }, {
      no = "non",
      yes = "oui",
      the = "le",
      good = "bon",
      goodbye = "au revoir",
      bye = "au revoir",
      cruel = "sadique"
    })
  end)
  it("find partial matches", function()
    assert.are.same({"é",1}, {english_to_french:lookup_partial("e")})
    assert.are.same({"beaucoup-",5}, {english_to_french:lookup_partial("multiverse")})
  end)
  it("not find partial matches which don't exist", function()
    assert.are.same({nil, 0}, {english_to_french:lookup_partial("x")})
    assert.are.same({nil, 0}, {english_to_french:lookup_partial("xy")})
    assert.are.same({nil, 0}, {english_to_french:lookup_partial("abcdefghij")})
  end)
  it("translate whole words", function()
    assert.are.equal("le", english_to_french.wholes["the"])
    assert.are.equal("au revoir", english_to_french.wholes["goodbye"])
    assert.are.equal("bon", english_to_french.wholes["good"])
  end)
  it("not crash when looking up strings of sizes not in the partial dictionary", function()
    assert.are.same({nil, 0}, {english_to_french:lookup_partial("to")})
    assert.are.same({nil, 0}, {english_to_french:lookup_partial("seventeen")})
  end)
  it("return the length of their longest string", function()
    assert.are.equal(5, english_to_french.partial.longest)
  end)
  it("return the length of their shortest string", function()
    assert.are.equal(1, english_to_french.partial.shortest)
  end)
end)

local blank
local eng
local french
local asterisk
describe("language", function()
  it("be creatable", function()
    asterisk = lang.new({ name = "asterisk" })
    blank = lang.new({ name = "blank", dictionary = blank_dict })
    eng = lang.new({ name = "eng" })
    french = lang.new({ name = "french", dictionary = english_to_french })
  end)
  it("default to asterisk obfuscation", function()
    assert.are.equal("*****", asterisk.obfuscate("fnord"))
  end)
  it("should create default abbreviations", function()
    assert.are.equal("blan",blank.abbrev)
    assert.are.equal("eng",eng.abbrev)
  end)
  it("use the first added lang as the default", function()
    assert.are.equal(asterisk, lang.default)
  end)
  it("should translate whole words", function()
    assert.are.equal("bon", french:translate("good"))
    assert.are.equal("Au revoir", french:translate("Goodbye"))
    assert.are.equal("au revoir", french:translate("bye"))
    assert.are.equal("SADIQUE", french:translate("CRUEL"))
    assert.are.equal("Beaucoup-", french:translate("MULti"))
  end)
  it("should translate partial words", function()
    assert.are.equal("beaucoup-vérsé", french:translate("multiverse"))
    assert.are.equal("vérsébeaucoup-", french:translate("versemulti"))
    assert.are.equal("vérséBeaucoup-", french:translate("verseMulti"))
    assert.are.equal("vérséBEAUCOUP-", french:translate("verseMULTI"))
  end)
  it("should match cases", function()
    assert.are.equal("Bon", lang.match_case("Good","bon"))
    assert.are.equal("B", lang.match_case("A","b"))
    assert.are.equal("BONJOUR", lang.match_case("HELLO","bonjour"))
    assert.are.equal("bonjour", lang.match_case("hELLO","bonjour"))
  end)
  it("use default with blank dictionaries", function()
    assert.are.equal("**********", blank:translate("multiverse"))
  end)
  describe("should", function()  
    local speech_problems_0 = asterisk:express(orig, 0, true)
    local speech_problems_30 = asterisk:express(orig, 30, true)
    local speech_problems_40 = asterisk:express(orig, 40, true)
    local speech_100 = asterisk:express(orig, 100, true)

    local writing_problems_0 = asterisk:express(orig, 0, false)
    local writing_problems_30 = asterisk:express(orig, 30, false)
    local writing_80 = asterisk:express(orig, 80, false)

    describe("flag words which cannot be", function()
      it("spoken", function()
        assert.are.same({"Goodbye","cruel","multiverse"}, speech_problems_0)
        assert.are.same({"Goodbye","multiverse"}, speech_problems_30)
        assert.are.same(orig, speech_100:translate(100))
      end)
      it("writen", function()
        assert.are.same({"Goodbye","cruel","multiverse"}, writing_problems_0)
        assert.are.same({"Goodbye","multiverse"}, writing_problems_30)
        assert.are.equal(80, writing_80.skill)
      end)
    end)
  end)
end)

describe("text", function()  
  local obf = "[yells] *******, [pauses] ***** **********! / plz DM kill me"
  local gcm = asterisk:express(orig, 80, false)
  it("should compute skill ranges", function()
    assert.are.equal(25, gcm.min_skill())
    assert.are.equal(50, gcm.max_skill())
  end)
  it("should obfuscate", function()
    assert.are.equal(obf, gcm.obfuscated())
    assert.are.equal(
      "[yells] Au revoir, [pauses] sadique beaucoup-vérsé! / plz DM kill me",
      french:express(orig, 80, true).obfuscated())
  end)
  it("should completely translate", function()
    assert.are.equal(orig, gcm:translate(gcm.max_skill()))
  end)
  it("should not translate", function()
    assert.are.equal(obf, gcm:translate(gcm.min_skill() - 1))
  end)
  it("should partially translate", function()
    assert.are.equal("[yells] *******, [pauses] cruel **********! / plz DM kill me", gcm:translate(30))
  end)
  it("can have its language identified", function()
    assert.are.equal(nil, gcm.id_language(5))
    assert.are.equal(asterisk, gcm.id_language(12.5))
    assert.are.equal(asterisk, gcm.id_language(100))
  end)
end)

describe("performance", function()
  local max_players = 128
  local pc_skills = {}
  it("process 1 sentence per 6 seconds from every player using less than 1% CPU", function()
    for i = 1, max_players do
      pc_skills[i] = i / 100
    end

    -- One minute of constant speaking:
    local seconds = 60

    local start = os.clock()
    for loop = 1, (seconds / 6) do
      for speaker = 1, max_players do
        local expressed = french:express(orig, 100, true)
        if expressed.is_text then
          for listener = 1, max_players do
            expressed:translate(pc_skills[listener])
          end
        end
      end
    end
    local elapsed = os.clock() - start

    -- print("% of CPU time: ", (100 * elapsed / seconds))
    assert.are.equal(elapsed < (seconds * 0.01), true)    
  end)
end)