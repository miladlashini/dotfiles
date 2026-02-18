-- Tabby setup
local theme = {
    fill = 'TabLineFill',
    head = 'TabLine',
    current_tab = 'TabLineSel',
    tab = 'TabLine',
    win = 'TabLine',
    tail = 'TabLine',
}

require('tabby').setup({
    line = function(line)
        return {
            {
                { '  ', hl = theme.head },
                line.sep('', theme.head, theme.fill),
            },
            line.tabs().foreach(function(tab)
                local hl = tab.is_current() and theme.current_tab or theme.tab
                return {
                    line.sep('', hl, theme.fill),
                    tab.is_current() and '' or '󰆣',
                    tab.number(),
                    tab.name(),
                    tab.close_btn(''),
                    line.sep('', hl, theme.fill),
                    hl = hl,
                    margin = ' ',
                }
            end),
            line.spacer(),
            line.wins_in_tab(line.api.get_current_tab()).foreach(function(win)
                return {
                    line.sep('', theme.win, theme.fill),
                    win.is_current() and '' or '',
                    win.buf_name(),
                    line.sep('', theme.win, theme.fill),
                    hl = theme.win,
                    margin = ' ',
                }
            end),
            {
                line.sep('', theme.tail, theme.fill),
                { '  ', hl = theme.tail },
            },
            hl = theme.fill,
        }
    end,
})

--------------------------------------------------
-- Tab Navigation Keymaps
--------------------------------------------------

-- New tab
vim.keymap.set('n', '<leader>tn', '<cmd>tabnew<CR>', { desc = 'New Tab' })

-- Close current tab
vim.keymap.set('n', '<leader>tc', '<cmd>tabclose<CR>', { desc = 'Close Tab' })

-- Go to tab by number
for i = 1, 9 do
    vim.keymap.set('n', '<leader>' .. i, i .. 'gt', { desc = 'Go to Tab ' .. i })
end

-- Move tab left / right
vim.keymap.set('n', '<leader>tmh', '<cmd>-tabmove<CR>', { desc = 'Move Tab Left' })
vim.keymap.set('n', '<leader>tml', '<cmd>+tabmove<CR>', { desc = 'Move Tab Right' })

-- Close all tabs except current
vim.keymap.set('n', '<leader>to', '<cmd>tabonly<CR>', { desc = 'Close Other Tabs' })
