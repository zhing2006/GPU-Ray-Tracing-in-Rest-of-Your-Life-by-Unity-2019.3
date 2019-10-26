using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

public static class PrintBounding
{
  [MenuItem("Tutorial/Print Bounding")]
  public static void Print()
  {
    var go = Selection.gameObjects[0];
    if (go)
    {
      var r = go.GetComponent<Renderer>();
      if (r)
        Debug.Log($"\"{go.name}\"'s bounding is [{r.bounds.min}]->[{r.bounds.max}]");
      else
        Debug.LogError($"No renderer on \"{go.name}\"");
    }
    else
    {
      Debug.LogError("Please select a game object.");
    }
  }
}
