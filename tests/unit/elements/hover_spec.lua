local async = require("dapui.async")
local a = async.tests
local Hover = require("dapui.elements.hover")
local tests = require("dapui.tests")
tests.bootstrap()
local mocks = tests.mocks

describe("hover element", function()
  ---@type dapui.elements.hover
  local hover
  local client, buf
  a.before_each(function()
    client = mocks.client({
      current_frame = {
        id = 1,
      },
      requests = {
        evaluate = mocks.evaluate({
          expressions = {
            a = "'a value'",
            ["b - 1"] = { result = "1", type = "number" },
            c = { result = "{ d = 1 }", type = "table", variablesReference = 1 },
          },
        }),
        variables = mocks.variables({
          variables = {
            [1] = {
              {
                name = "d",
                value = "1",
                type = "number",
                variablesReference = 0,
              },
            },
          },
        }),
      },
    })
    hover = Hover(client)
    buf = hover.buffer()
  end)
  after_each(function()
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
    hover = nil
  end)
  a.it("renders lines", function()
    hover.set_expression("a")
    async.util.sleep(10)
    local lines = async.api.nvim_buf_get_lines(buf, 0, -1, false)
    assert.same({ "a = 'a value'" }, lines)
  end)
  a.it("renders lines after expression update", function()
    hover.set_expression("a")
    hover.set_expression("b - 1")
    async.util.sleep(10)
    local lines = async.api.nvim_buf_get_lines(buf, 0, -1, false)
    assert.same({ "b - 1 number = 1" }, lines)
  end)

  a.it("renders lines with expandable expression", function()
    hover.set_expression("c")
    async.util.sleep(10)
    local lines = async.api.nvim_buf_get_lines(buf, 0, -1, false)
    assert.same({ " c table = { d = 1 }" }, lines)
  end)

  a.it("renders highlights with expandable expression", function()
    hover.set_expression("c")
    async.util.sleep(10)
    local extmarks =
      async.api.nvim_buf_get_extmarks(buf, tests.namespace, 0, -1, { details = true })
    local formatted = tests.util.convert_extmarks(extmarks)
    assert.same({
      { "DapUIDecoration", 0, 0, 0, 0 },
      { "DapUIType", 0, 6, 0, 6 },
      { "DapUIValue", 0, 14, 0, 14 },
    }, formatted)
  end)

  describe("with expanded variables", function()
    a.it("renders expanded lines", function()
      hover.set_expression("c")
      async.util.sleep(10)
      local keymaps = tests.util.get_mappings(hover.buffer())
      keymaps["<CR>"](1)

      local lines = async.api.nvim_buf_get_lines(buf, 0, -1, false)
      assert.same({ " c table = { d = 1 }", "   d number = 1" }, lines)
    end)
    a.it("renders expanded highlights", function()
      hover.set_expression("c")
      async.util.sleep(10)
      local keymaps = tests.util.get_mappings(hover.buffer())
      keymaps["<CR>"](1)

      local extmarks =
        async.api.nvim_buf_get_extmarks(buf, tests.namespace, 0, -1, { details = true })
      local formatted = tests.util.convert_extmarks(extmarks)
      assert.same({
        { "DapUIDecoration", 0, 0, 0, 0 },
        { "DapUIType", 0, 6, 0, 6 },
        { "DapUIValue", 0, 14, 0, 14 },
        { "DapUIDecoration", 1, 1, 1, 1 },
        { "DapUIVariable", 1, 3, 1, 3 },
        { "DapUIType", 1, 5, 1, 5 },
        { "DapUIValue", 1, 14, 1, 14 },
      }, formatted)
    end)
  end)
end)
