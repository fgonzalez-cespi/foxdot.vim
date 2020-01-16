import os
import cmd
import re as regex

from FoxDot import *

class FoxDotConsole(cmd.Cmd):
    prompt = "FoxDot> "
    intro = "LiveCoding with Python and SuperCollider"
    stack = ''

    def default(self, line):
        p = regex.compile('^\.', regex.MULTILINE)
        if line == '[STACK-SEND]':
            # execute(self.stack.replace('.', ''))
            execute(p.sub('', self.stack))
            self.stack = ''
        else:
            self.stack += line + "\n"
            # print self.stack

if __name__ == "__main__":
    FoxDotConsole().cmdloop()
