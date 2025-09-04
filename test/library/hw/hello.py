from robot.api.deco import keyword, library

#---------------------------------------------------------------------------------------------------
@library
class Library:
    @keyword
    def print(self, msg):
        print(msg + "\n")
