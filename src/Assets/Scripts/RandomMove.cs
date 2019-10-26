using UnityEngine;
using Random = UnityEngine.Random;

public class RandomMove : MonoBehaviour
{
  private Animation _anim;
  private AnimationState _state;

  public void Awake()
  {
    _anim = GetComponent<Animation>();
    _state = _anim.PlayQueued("Movement", QueueMode.PlayNow, PlayMode.StopAll);
    _state.speed = 0.0f;
  }

  public void Update()
  {
    SceneManager.Instance.isDirty = true;
    _state.normalizedTime = Random.value;
  }
}
