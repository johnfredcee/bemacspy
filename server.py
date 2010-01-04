#!/usr/bin/env python


import socket
import select
import Blender
import cmd
import sys
import code
import os

__version__ = "0.1"
client = None
address = None

def blender_raw_input(prompt):
    """Take raw input from blender"""
    print prompt
    Blender.Redraw()
    return raw_input("Blender>>>")

class BlenderCmd(cmd.Cmd, object):
    banner = (  'Blender Remote Interactive Python %s Shell v%s\n' % ( sys.version, __version__))
    
    """Simple command processor example."""
    def __init__(self, cmd_in, cmd_out):
        cmd.Cmd.__init__(self, None, cmd_in, cmd_out)

    def default(self):
        print "** unknown syntax ", line
        return
    
    def do_run(self, line):
        print "Running ", line
        Blender.Run(line)

    def do_interact(self, line):
        """standard code interpreter loop"""
        code.interact(self.banner, blender_raw_input)
        
    def do_EOF(self, line):
        return True

    def do_cwd(self, line):
        print os.chdir(line)

    def do_dir(self, line):
        for file in os.listdir(os.getcwd()):
            print file
            
    def do_pwd(self, line):
        print os.getcwd()        

    def do_suspend(self, line):
        print "Suspending .. press q to quit.."
        unsuspend = False
        while not(unsuspend):
            ( readfrom, writeto, haderror ) = select.select( [ client ], [ ], [ ], 1 )
            if (readfrom):
                letter = readfrom[0].recv(1)
                unsuspend = ( letter == "q" )
            Blender.sys.sleep()
            
            
    def do_quit(self, line):
        return True

    def preloop(self):
        Blender.Redraw()

    def precmd(self, line):
        Blender.Redraw()
        return line
    
    def postcmd(self, stop, line):
        Blender.Redraw()
        return stop
    
    def postloop(self):
        Blender.Redraw()
        
class STDFilePointers:
    """proxy for file pointers

    can be used to redirect sys.stdin, sys.stdout and sys.stderr to a
    socket
    """
    def __init__(self, conn):
        self.conn = conn

    def write(self, s):
        self.conn.send(s)

    def read(self, l):
        r = self.conn.recv(l)
        #if not r:
        #    raise IOError('Connection closed')
        return r or ' '

    def readline(self):
        data = []
        while 1:
            c = self.read(1)
            if c == '\n':
                return ''.join(data) + '\n'
            data.append(c)
    
host = '127.0.0.1'
port = 50000
backlog = 1
size = 1024
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.bind((host,port))
s.listen(backlog)
client, address = s.accept()
print "Made connection"
tick = 0
stdfps = STDFilePointers(client)
blenderout = sys.stdout
blendererr = sys.stdout
blenderin = sys.stdin
sys.stdin = stdfps
sys.stdout = stdfps
sys.stderr = stdfps
interpreter = BlenderCmd(blenderin, blenderout)
interpreter.cmdloop()
sys.stdout = blenderout
sys.stderr = blendererr
sys.stdin = blenderin
client.close() 
