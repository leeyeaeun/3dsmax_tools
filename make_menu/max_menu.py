import MaxPlus
import os

def dir_list_folder(head_dir, dir_name):
    """Return a list of the full paths of the subdirectories
    under directory 'head_dir' named 'dir_name'"""
    dirList = []
    for fn in os.listdir(head_dir):
        dirfile = os.path.join(head_dir, fn)
        if os.path.isdir(dirfile):
            if fn.upper() == dir_name.upper():
                dirList.append(dirfile)
            else:
                dirList += dir_list_folder(dirfile, dir_name)
        if dirList != []:
            break
    return dirList

def find_file_by_name(point,target):
    """Return a Launcher path under 'point' """
    launcher_path = ""
    for (path, dir, files) in os.walk(point):
        for filename in files:
            # if target in filename:
            if filename == target:
                launcher_path = os.path.join(path, filename)
    return launcher_path


def max_menu_build(target_dict):
    """
    :param target_dict:
        {project name : launcher path}
    make menu on 3ds max
    """
    # make main menu
    mxs_cmd1 = """
    theMainMenu = menuMan.getMainMenuBar() --get the main menu bar
    try (menuMan.unRegisterMenu (menuMan.findMenu "DATAHUB") ) catch()
    theMenu = menuMan.createMenu "DATAHUB" --create a menu called Forum Help
    theSubMenu = menuMan.createSubMenuItem "DATAHUB" theMenu --create a SubMenuItem
    theMainMenu.addItem theSubMenu (theMainMenu.numItems()+1) --add the SubMenu to the Main Menu"""
    MaxPlus.Core.EvalMAXScript(mxs_cmd1)

    # make macro & add actions
    for i in range(len(target_dict.keys())):
        mxs_cmd2 = ("""
        macroScript {target_name} category:"DATAHUB" --some macro script
        (
            try(
                python.executeFile @"{target_path}"
            )catch(
                messageBox("can't import " + "{target_name}" + "\n" + "make sure this project is setup")
                print ("can't import " + "{target_path}" + "\n" + "make sure this project is setup")
            )
        )
        theAction = menuMan.createActionItem "{target_name}" "DATAHUB"
        theMenu.addItem theAction (theMenu.numItems()+1) """).format(target_name=target_dict.keys()[i],target_path=target_dict[target_dict.keys()[i]])
        MaxPlus.Core.EvalMAXScript(mxs_cmd2)

    mxs_cmd3= ("""menuMan.updateMenuBar() --update the menu bar""")
    MaxPlus.Core.EvalMAXScript(mxs_cmd3)

    print "done"

def menu_build():
    startPointDir = r"D:\sel-dev"

    import pymxs
    rt = pymxs.runtime
    startPointDir = rt.startPointDir

    prj_list = [
        "materialator",
        "datahub_id_wizard",
        "light_tool",
        "datahub_assembler",
        "rengo_inspector",
        "assetui",
        "vse_preset_ui",
        "vse_manager",
        "riggi",
        "matsubator",
        "work_context",
        "geomui",
        "camera_tool",
        "animation",
        "hkmc_converter",
        "hkmc_assembler"
    ]
    launcher_dict = {}
    for i in prj_list:
        dir_list = dir_list_folder(startPointDir, i)
        if dir_list:
            dir = dir_list[0]
            launcher = find_file_by_name(dir,"launcher.py")
            if launcher == "":
                launcher = find_file_by_name(dir,i+"_launcher.py")
            if launcher != "":
                launcher_dict[i] = launcher
                print i + ": succese"

        #     else:
        #         print i + ": launcher not found "
        # else:
        #     print i + ": launcher not found "

    max_menu_build(launcher_dict)

if __name__ == "__main__":
    menu_build()
