-- ！！！这个库包含在你自己工程内的相对路径！！！
local CurLibSavePath = ';./?.lua'
package.path = package.path .. CurLibSavePath
-- 命名空间
CO = {}
require 'COConf'
require 'Misc'
CO.Stack = require 'Stack'
require 'Task'
require 'Event'
require 'CoTree'

require 'Wait.Lib'

require 'AsyncDo.Lib'
