using UnityEngine;

/// <summary>
/// the motion blur asset.
/// </summary>
[CreateAssetMenu(fileName = "MotionBlurAsset", menuName = "Rendering/MotionBlurAsset")]
public class MotionBlurAsset : RayTracingTutorialAsset
{
  /// <summary>
  /// create tutorial.
  /// </summary>
  /// <returns>the tutorial.</returns>
  public override RayTracingTutorial CreateTutorial()
  {
    return new MotionBlur(this);
  }
}
