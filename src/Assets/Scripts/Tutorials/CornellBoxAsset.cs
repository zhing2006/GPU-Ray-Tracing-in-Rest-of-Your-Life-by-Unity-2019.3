using UnityEngine;

/// <summary>
/// the cornell box. asset.
/// </summary>
[CreateAssetMenu(fileName = "CornellBoxAsset", menuName = "Rendering/CornellBoxAsset")]
public class CornellBoxAsset : RayTracingTutorialAsset
{
  /// <summary>
  /// create tutorial.
  /// </summary>
  /// <returns>the tutorial.</returns>
  public override RayTracingTutorial CreateTutorial()
  {
    return new CornellBox(this);
  }
}
