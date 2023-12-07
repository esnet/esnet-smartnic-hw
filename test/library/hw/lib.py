from robot.api.deco import keyword, library

#-------------------------------------------------------------------------------
@library
class Library:
    @keyword
    def display(self, msg):
        print(msg + "\n")
