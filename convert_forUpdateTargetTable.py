
import sys
import os

dir = os.path.dirname(__file__)
filename = os.path.join(dir,'libs')
sys.path.append(filename)

import pymysql,re
import time
import random

def makeTxt(fileName,contents,savePath):
    print savePath
    f = open( savePath +"\\" +fileName+'.txt', 'w')
    f.write(contents)
    f.close()

def execute_compare(convert,car,partlist,low,partdic) :
       print convert
       print car
       print partlist
       print low
       print partdic

       conn = con_mv_db()
       cur = conn.cursor()

       if convert:
              if( find_vhcCd(car,cur) ==()) :
                     print "there is no vhc code like " + car
                     for i in partlist :  insertAll(car,i,cur,low,1)
              else :
                     for i in partlist :
                            result = find_partNo(car,cur,i)
                            if result == () : insertAll(car,i,cur,low,1)
                            else : 
                                   updateLow(car,cur,result,i,low,1)
       else:
              for key in partdic.keys():
                     oldResult = find_partNo(car,cur,key)
                     newResult = find_partNo(car,cur,partdic[key])

                     if oldResult == () :
                            insertAll(car,key,cur,low,0)
                     elif oldResult != ():
                            updateLow(car,cur,oldResult,key,low,0)

                     if newResult == () : 
                            insertAll(car,partdic[key],cur,low,1)
                     elif newResult != () :
                            updateLow(car,cur,newResult,partdic[key],low,1)

       conn.commit()

def getDataFromText ():
       convert = True
       car = ""
       partlist = []
       low = False
       partdic = {}
       maxName = ""
       contents = ""
       thisFilePath = os.path.dirname( os.path.abspath( __file__ ) )
       txtFile = thisFilePath + "/txt/FORDB.txt"

       f = open(txtFile, 'r')
       allstr =f.read()
       if allstr.find("change") != -1:
              convert = False

       f = open(txtFile, 'r')
       lines = f.readlines()
       contentsTxt = ""
       for line in lines:
              if line.startswith("max"):
                     maxName = line.strip().split(":")[1]
              if convert:
                     partsForTxt = ""
                     newline = line.strip().split(":")
                     print  newline    

                     if newline[0] == "vhcCode" :
                            car = newline[1]
                     elif newline[0] == "partNo" :
                            partsForTxt = newline[1]
                            partlist = partsForTxt.split(",")
                            partlist = filter(None, partlist)
                     elif newline[0] == "lowhigh" :
                            if (newline[1] == "low") : 
                                   low = True
                     contents = "Convert\n"+car + "\n" + str(partlist) + "\n" +  time.strftime("%Y%m%d")
              else:

                     newline = line.strip().split("-")
                     if newline[0] == "carname" :
                           car = newline[1]
                     elif newline[0] == "list" :
                            contentsTxt = newline[1]
                            replaced=newline[1].replace("#","").replace("(","").replace("\"","").replace(")","")
                            changedSplit=replaced.split(",")
                            for partname in changedSplit:
                                   oldname=(partname.split(":")[0]).strip()
                                   newname=(partname.split(":")[1]).strip()
                                   partdic[oldname] = newname
                     elif newline[0] == "lowhigh" :
                            if (newline[1] == "low") : 
                                   low = True
                     contents = "Change Num\n" + car + "\n" + contentsTxt + "\n" +  time.strftime("%Y%m%d")

       makeTxt(maxName + str(random.random())[2:9], contents, r"\\data\SEL-EDITORIAL\06_DATA_TRANSFER\_DBINSERT_RECORD")
       f.close()
       execute_compare(convert,car,partlist,low,partdic)


######################################################################


#DB Connection
def con_mv_db():
       print "DB connet...."
       conn = pymysql.connect(host='sv-sel-gdbd001', user="pdm_write", password="pdm_pass",
                                                 db='mv_db', charset='utf8')
       return conn


def find_vhcCd(car, cur):
       print "find vehicle code : " + car

       sql = "SELECT target_no FROM target WHERE vhc_cd = %s"
       cur.execute(sql,(car))
       result = cur.fetchall()

       return result

def find_partNo(car ,cur,i):
       print "find part no : " + car +" / "+i
       sql = "SELECT * FROM target WHERE vhc_cd = %s AND target_no = %s  "
       cur.execute(sql,(car , i))   
       result = cur.fetchall()
       return result

def insertAll(car,partNo,cur,low,hold):
       print partNo + " : insert in python---------------------------------------------------------"
       if low : 
              sql = "INSERT INTO target (vhc_cd, target_no, low) VALUES (%s,%s,%s)"
       else:
              sql = "INSERT INTO target (vhc_cd, target_no, high) VALUES (%s,%s,%s)"

       cur.execute(sql,(car, partNo,hold))
       
def updateLow(car,cur, result,partNo,low,hold):
       print  partNo+ " : update in python---------------------------------------------------------" 
       sql = ""
       if (low == True) :
              sql = "UPDATE target SET low = %s WHERE vhc_cd = %s AND target_no = %s"
              cur.execute(sql,(hold,car, partNo))
       elif(low == False) : 
              sql = "UPDATE target SET high = %s WHERE vhc_cd = %s AND target_no = %s"
              cur.execute(sql,(hold, car, partNo))
       


if __name__  == "__main__" :
       getDataFromText()
