import 'dart:convert';
import 'dart:io';

class DaeFix {
  //this parameter will allow us to find correct space between start string and main component <asset>
  bool asset_found = false;
  //parameter of standard space that have every main tags because of xml standard
  String html_etalon_space = "";
  //this parameter will allow us to find correct open tag
  String open_tag = "";
  //this parameter will allow us to find correct closed tag for previously opened
  String closed_tag = "";
  //do we in library_geometries part
  bool isLibraryGeometries = false;
  //do we in library_controllers part
  bool isControllersNeedToBeFixed = false;
  //do we in library_animations part
  bool isLibraryAnimations = false;
  //do we in library_visual_scenes part
  bool isLibraryVisualScenes = false;
  //name of morph (url) for skin controller which should be  changed
  String skin = "";
  //names of morph controllers
  Set<String> morph = {};
  //json for config file
  Map<String, Object> data = {};
  //List of blendshapes
  Map<String, Object> bs_AR = {};
  //List of blendshapes
  Map<String, Object> bs_custom = {};
  //List of animations containers
  String anim_container = "";
  //List of animations names
  List<String> anim_names = [];
  //List of animations
  Map<String, List<String>> anim = {};
  //do instance_controller
  bool ic = false;

  static Map<String, String> controller_target = {};
  static String controller_morh_name = "";
  static Map<String, String> AR_Apple = {
    "browInnerUp": "browInnerUp",
    "browDownLeft": "browDown_L",
    "browDownRight": "browDown_R",
    "browOuterUpLeft": "browOuterUp_L",
    "browOuterUpRight": "browOuterUp_R",
    "eyeLookUpLeft": "eyeLookUp_L",
    "eyeLookUpRight": "eyeLookUp_R",
    "eyeLookDownLeft": "eyeLookDown_L",
    "eyeLookDownRight": "eyeLookDown_R",
    "eyeLookInLeft": "eyeLookIn_L",
    "eyeLookInRight": "eyeLookIn_R",
    "eyeLookOutLeft": "eyeLookOut_L",
    "eyeLookOutRight": "eyeLookOut_R",
    "eyeBlinkLeft": "eyeBlink_L",
    "eyeBlinkRight": "eyeBlink_R",
    "eyeSquintLeft": "eyeSquint_L",
    "eyeSquintRight": "eyeSquint_R",
    "eyeWideLeft": "eyeWide_L",
    "eyeWideRight": "eyeWide_R",
    "cheekPuff": "cheekPuff",
    "cheekSquintLeft": "cheekSquint_L",
    "cheekSquintRight": "cheekSquint_R",
    "noseSneerLeft": "noseSneer_L",
    "noseSneerRight": "noseSneer_R",
    "jawOpen": "jawOpen",
    "jawForward": "jawForward",
    "jawLeft": "jawLeft",
    "jawRight": "jawRight",
    "mouthFunnel": "mouthFunnel",
    "mouthPucker": "mouthPucker",
    "mouthLeft": "mouthLeft",
    "mouthRight": "mouthRight",
    "mouthRollUpper": "mouthRollUpper",
    "mouthRollLower": "mouthRollLower",
    "mouthShrugUpper": "mouthShrugUpper",
    "mouthShrugLower": "mouthShrugLower",
    "mouthClose": "mouthClose",
    "mouthSmileLeft": "mouthSmile_L",
    "mouthSmileRight": "mouthSmile_R",
    "mouthFrownLeft": "mouthFrown_L",
    "mouthFrownRight": "mouthFrown_R",
    "mouthDimpleLeft": "mouthDimple_L",
    "mouthDimpleRight": "mouthDimple_R",
    "mouthUpperUpLeft": "mouthUpperUp_L",
    "mouthUpperUpRight": "mouthUpperUp_R",
    "mouthLowerDownLeft": "mouthLowerDown_L",
    "mouthLowerDownRight": "mouthLowerDown_R",
    "mouthPressLeft": "mouthPress_L",
    "mouthPressRight": "mouthPress_R",
    "mouthStretchLeft": "mouthStretch_L",
    "mouthStretchRight": "mouthStretch_R",
    "tongueOut": "tongueOut",
  };

  Future<String> main(String path, bool convertRequired) async {
    // Gson gson = new Gson();

    //path to the certain file that will be copied
    File file_sourse = File(path);
    //path to the new copy of file that will be fixed
    File file_dest = File(path.replaceAll(".dae", "-fixed.dae"));

    //copy .dae original file
    //copyFileUsingStream(file_sourse,file_dest);
    print(path.replaceAll(".dae", ".scn"));
    //read string by string the copy of -fixed.dae file
    await ReadWithBufferedReader(file_sourse, file_dest).then((value) {
      if (convertRequired) {
        Process.run(
          "xcrun",
          [
            "scntool",
            "--convert",
            path.replaceAll(".dae", "-fixed.dae"),
            "--format",
            "scn",
            "--output",
            path.replaceAll(".dae", ".scn"),
            "--force-y-up",
            "--force-interleaved",
            "--resources-folder-path = ./",
            "--asset-catalog-path = ./"
          ],
        ).then((value) => print(value.stdout));
      }
    });

    String json = jsonEncode(configure());

    print(bs_custom);
    print(bs_AR);
    print(anim);

    return "Done.\nPath to ${convertRequired ? "SCN" : "DAE"} file - ${path.replaceAll(".dae", convertRequired ? ".scn" : "-fixed.dae")}";
  }

  //read file string by string
  //and execute other code
  Future<void> ReadWithBufferedReader(
      File file_original, File file_fixed) async {
    final reader = file_original.readAsLinesSync();

    String currentLine;
    String changedLine = "";
    final writer = [];
    for (var line in reader) {
      currentLine = line;
      changedLine = searchStringByString(currentLine);

      // writer.writeAsStringSync(changedLine);
      // writer.write("\n");
      configureList(changedLine);
      // print(changedLine);
      writer.add(changedLine);
      // file_fixed.writeAsString(changedLine, mode: FileMode.append, flush: true);
    }

    await file_fixed.writeAsString(writer.join('\n'));
    print(file_fixed);
  }

  //
  String searchStringByString(String str_dae_file) {
    //main tags that will be checked if them are closed
    final html_tags = [
      "<library_geometries>",
      "<library_controllers>",
      "<library_animations>",
      "<library_visual_scenes>"
    ];

    //search in entering string the tag <asset> and write the spase before it to html_etalon_spase
    if (!asset_found) {
      final length = str_dae_file.split('<')[0];
      html_etalon_space =
          str_dae_file.contains(RegExp("^.*<asset>")) ? length : "";
    }
    //change key asset_found to true when standard space is found
    if (html_etalon_space.isEmpty) {
      asset_found = true;
    }
    //before standard space is found do not go farther this point
    if (asset_found == false) {
      return str_dae_file;
    }

    //
    //-------Part_1-------
    //

    //checking only strings with main tags and fix it if there is no closed tags
    if (str_dae_file.contains(RegExp("^$html_etalon_space<.*"))) {
      str_dae_file = isClosedTagExist(str_dae_file);
    }

    //
    //-------Part_2-------
    //

    //extracting mesh with morphs names
    if (str_dae_file.contains(RegExp(html_etalon_space + html_tags[0])) ||
        isLibraryGeometries) {
      isLibraryGeometries = true;
      morphNamesExtruding(str_dae_file);
    }

    //if there is morph and skin controllers should be modified
    if (str_dae_file.contains(RegExp(html_etalon_space + html_tags[1])) ||
        isControllersNeedToBeFixed) {
      isControllersNeedToBeFixed = true;
      return controllerFixing(str_dae_file);
    }

    //
    //-------Part_3-------
    //

    //extracting mesh with morphs names
    if (str_dae_file.contains(RegExp(html_etalon_space + html_tags[2])) ||
        isLibraryAnimations) {
      isLibraryAnimations = true;
      return aninationsFixing(str_dae_file);
    }

    //
    //-------Part_4-------
    //

    //extracting mesh with morphs names
    if (str_dae_file.contains(RegExp(html_etalon_space + html_tags[3])) ||
        isLibraryVisualScenes) {
      isLibraryVisualScenes = true;
      return libraryVisualScenesFixing(str_dae_file);
    }
    asset_found = false;
    return str_dae_file;
  }

  //check if closed tags exist and if no add it
  String isClosedTagExist(String tag) {
    String temp = "";
    //regrep expression to extract open tag name
    Pattern pattern = RegExp("<(.*?)>");
    final matcher = pattern.allMatches(tag);

    //open_tag is emtpy in two cases: search for first time and if previous tag have been closed
    if (open_tag.isEmpty) {
      if (!tag.contains("/")) {
        if (matcher.isNotEmpty) {
          open_tag = matcher.first.group(1)!;
        }
      }
      //remember the open tag and return unmodified string
      return tag;
    }

    //if open_tag is not Empty then we search for its closer_tag
    if (tag.contains(RegExp("$html_etalon_space</$open_tag>"))) {
      open_tag = "";
      //closer_tag is exist, so we clear the open tag and return unmodified string
      return tag;
    }

    //if open_tag is not Empty and string doesn't contens "/"
    // then it is next opening tag, so we should to close previous one
    else if (!tag.contains("/")) {
      closed_tag = "$html_etalon_space</$open_tag>";
      if (matcher.isNotEmpty) {
        open_tag = matcher.first.group(1)!;
      }
      //create closer_tag
      // and clear the open_tag and closer_tag
      // and return modified string
      temp = "$closed_tag\n$html_etalon_space<$open_tag>";
      open_tag = "";
      closed_tag = "";
      return temp;
    }
    //in case if there is closed_tag without any open_tag
    //this case should not exist
    return "$tag<!--tag should be fixed-->";
  }

  //collecting names of meshes with morphs to use them later in library_controllers part
  void morphNamesExtruding(String string) {
    //if we out of <library_geometries> part
    if (string.contains(RegExp("</library_geometries>")))
      isLibraryGeometries = false;
    //regrep expression to extract geometry with morphs name
    Pattern pattern = RegExp("\"(.*?)-mesh");
    final matcher = pattern.allMatches(string);

    if (string.contains("<geometry id") && string.contains("-mesh_morph")) {
      if (matcher.isNotEmpty) {
        morph.add("${matcher.first.group(1)!}-morph");
      }
    }
  }

  //changing armature controllers sources
  String controllerFixing(String string) {
    //if we out of <library_controllers> part
    if (string.contains("</library_controllers>")) {
      isControllersNeedToBeFixed = false;
    }
    String controller_name = "";

    if (string.contains("<IDREF_array")) {
      for (String ar in AR_Apple.keys) {
        string = string.replaceAll(ar, AR_Apple[ar] ?? ar);
      }
    }

    //regrep expression to extract controller name
    Pattern pattern = RegExp("\"(.*?)\"");
    final matcher = pattern.allMatches(string);

    //when we found controller we check if it skin (armature) controller
    //and if so we check if there is a morphs on object of controller
    if (string.contains("<controller")) {
      if (string.contains("-morph\"")) {
        if (matcher.isNotEmpty) {
          controller_name = matcher.first.group(1)!;

          controller_morh_name = controller_name;
        }
      }
      if (string.contains("-skin\"")) {
        if (matcher.isNotEmpty) {
          controller_name = matcher.first.group(1)!;
          for (String m in morph) {
            if (controller_name.contains(m.replaceAll("-morph", "")))
            //remember the name of morph (which need to correct url)
            {
              skin = m;
            }
          }
        }
      }
    }

    if (!controller_morh_name.isEmpty && string.contains("<morph source")) {
      if (matcher.isNotEmpty) {
        controller_target[controller_morh_name] = matcher.first.group(1)!;
      }
    }

    //if string starts with <skin sourse then it is string that we should modify
    if (!skin.isEmpty && string.contains("<skin source")) {
      if (matcher.isNotEmpty) {
        //replase old url on new with morph link
        string = string.replaceAll(matcher.first.group(1)!, "#$skin");
        //and clear the skin
        skin = "";
        return string;
      }
    }
    return string;
  }

  //fixing animations
  String aninationsFixing(String string) {
    //if we out of <library_animations> part
    if (string.contains("</library_animations>")) {
      isLibraryAnimations = false;
    }

    if (string.contains(
            "$html_etalon_space$html_etalon_space<(.?)animation id(.*?)") ||
        string.contains("$html_etalon_space$html_etalon_space</animation>")) {
      Pattern pattern = RegExp("<animation id=\"(.*?)\"");
      final matcher = pattern.allMatches(string);
      if (matcher.isNotEmpty) {
        //the animation name
        anim_container = matcher.first.group(1)!;
      }
      return string;
    } else if (string.contains("<animation") ||
        string.contains("</animation>")) {
      Pattern pattern = RegExp("<animation id=\"[^_]*_(.+?)_");
      final matcher = pattern.allMatches(string);
      final temp_list = <String>[];

      if (matcher.isNotEmpty) {
        //the animation name
        if (!anim_container.isEmpty) {
          try {
            temp_list.addAll(anim[anim_container]!.toList());
            temp_list.add(matcher.first.group(1)!);
            anim[anim_container] = temp_list;
          } catch (e) {
            anim[anim_container] = [matcher.first.group(1)!];
          }
        }
      }

      return "";
    }

    return string;
  }

  //fixing instance controllers
  String libraryVisualScenesFixing(String string) {
    //if we out of <library_visual_scenes> part
    if (string.contains("</library_visual_scenes>")) {
      isLibraryVisualScenes = false;
    }

    if (string.contains("instance_geometry")) {
      for (String ct in controller_target.keys) {
        if (string.contains(controller_target[ct] ?? '!!!!')) {
          ic = true;
          return string
              .replaceAll("geometry", "controller")
              .replaceAll(controller_target[ct] ?? '!!!!', "#" + ct);
        }
      }
      if (ic) {
        ic = false;
        return string.replaceAll("geometry", "controller");
      }
      // return string.replaceAll("geometry", "controller");
    }
    return string;
  }

  //method to copy original .dae file
  //  void copyFileUsingStream(File source, File dest)  {
  //       InputStream is = null;
  //       OutputStream os = null;
  //       try {
  //           is = new FileInputStream(source);
  //           os = new FileOutputStream(dest);
  //           byte[] buffer = new byte[1024];
  //           int length;
  //           while ((length = is.read(buffer)) > 0) {
  //               os.write(buffer, 0, length);
  //           }
  //       } finally {
  //           is.close();
  //           os.close();
  //       }
  //   }

  Map<String, Object> configure() {
    Map<String, Object> model = Map<String, Object>();

    model["blendShapesCustom"] = bs_custom;
    model["blendShapesAR"] = bs_AR;
    model["animations"] = anim;

    data["model"] = model;
    return data;
  }

  void configureList(String line) {
    //for mesh name with blendshapes
    String mesh_names = "";
    //names of blendhapes on certain mesh (Custom)
    List<String> bs_names = [];
    //names of blendhapes on certain mesh (AR Apple)
    List<String> bs_names_AR = [];

    //Bledshapes lie in line that starts with <IDREF_array id=...
    //so we check if the corrected line is line with blendshapes
    if (line.contains("<IDREF_array")) {
      //here in (.*?) we extract name of mesh that contains blendshapes
      Pattern pattern =
          RegExp("<IDREF_array id=\"(.*?)-targets-array\" count=");
      final matcher = pattern.allMatches(line);
      if (matcher.isNotEmpty) {
        //the mesh name with blendshapes (bs)
        mesh_names = matcher.first.group(1)!;
      }

      //delete closing hashtag "</IDREF_array>" from line
      //delete all references on mesh name in blendshapes name
      //delete unnecessary spaces
      //split the line with "-mesh_morph_"
      bs_names.addAll(line
          .replaceAll("</IDREF_array>", "")
          .replaceAll(mesh_names, "")
          .replaceAll(" ", "")
          .split("-mesh_morph_"));
      //remove first element which contains "<IDREF_array id=..."
      bs_names.remove(0);
      //duble bs list
      bs_names_AR.addAll(bs_names);

      //remove AR bs
      bs_names.removeWhere((n) => (AR_Apple[n]?.contains(n) ?? false));
      //remove custom bs
      bs_names_AR.removeWhere((n) => (!(AR_Apple[n]?.contains(n) ?? false)));

      bs_custom[mesh_names] = bs_names;
      bs_AR[mesh_names] = bs_names_AR;
    }
  }
}
