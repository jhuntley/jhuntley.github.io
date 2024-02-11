---
title: Netcode for Entities - Spawning Player Cameras 
description: A short post detailing how to spawn cameras for individual players in Unity using their Entity Component System and Netcode for Entities
date: "2024-02-11T13:43:40"
draft: false
tags: 
---

# Leveraging Unity's Megacity Multiplayer Sample

After struggling to implement my own solution, I decided to dive into Unity's Megacity Multiplayer sample and see if there was anything in there that might be able to help me get the cameras running. It took me a little while to wrap my head around the codebase, but it turns out thay they were using a hybrid solution that was quite similar to what I had tried. The key difference, however, was that instead of trying to pass a singleton information about the players (my attempted solution), the unity developers let an ISystem paired with an IJobEntity pass information via a singleton -- the Hybrid Camera Manager.

# First Steps

The first step to get this rolling is to make sure there's actually a component available that the IJobEntity job mentioned above can find. I've gone ahead and named this component PlayerCameraTarget (following the sample), as it will store the current player data for the camera.

The next step is to create the ISystem script (PlayerCameraTargetUpdated) that will grab the component PlayerCameraTarget as a singleton (only one per client) and pass its information on to the Hybrid Camera Manager. Here is the script in question:

```
using Unity.Burst;
using Unity.Entities;
using Unity.Transforms;

namespace Unity.Megacity.CameraManagement
{
    /// <summary>
    /// Updates player camera target position and rotation
    /// </summary>
    [BurstCompile]
    [UpdateAfter(typeof(TransformSystemGroup))]
    [WorldSystemFilter(WorldSystemFilterFlags.LocalSimulation | WorldSystemFilterFlags.ClientSimulation)]
    public partial struct Sys_PlayerCameraTargetUpdater : ISystem
    {
        public EntityQuery m_CameraTarget;
        public void OnCreate(ref SystemState state)
        {
            m_CameraTarget = state.GetEntityQuery(ComponentType.ReadOnly<PlayerCameraTarget>(),ComponentType.ReadOnly<LocalToWorld>());
            state.RequireForUpdate(m_CameraTarget);
        }

        public void OnUpdate(ref SystemState state)
        {
            var cameraTarget = SystemAPI.GetSingleton<PlayerCameraTarget>();
            var deltaTime = state.WorldUnmanaged.Time.DeltaTime;
            
            if (!HybridCameraManager.Instance.IsCameraReady)
                HybridCameraManager.Instance.PlaceCamera(cameraTarget.Position);
            
            HybridCameraManager.Instance.SetPlayerCameraPosition(cameraTarget.Position, deltaTime);
            HybridCameraManager.Instance.SetPlayerCameraRotation(cameraTarget.Rotation, deltaTime);
        }
    }
}
```

Once that script has been created, then we can move ahead and create the actual Hybrid Camera Manager. The Unity version of this script contains far more features than I need. Here is my modified version of the code:

```
using System;
using Unity.Mathematics;
using UnityEngine;

namespace Pool
{
    /// <summary>
    /// Create camera target authoring component in order to
    /// allow the game object camera to follow the player camera target entity
    /// </summary>
    public class HybridCameraManager : MonoBehaviour
    {
        
        [SerializeField]
        private float m_TargetFollowDamping = 5.0f;
        [SerializeField]
        private Transform m_PlayerCameraTarget;
        [SerializeField] 
        private GameObject m_AutopilotCamera;
        
        public bool IsCameraReady { private set; get; }

        public static HybridCameraManager Instance;
    
        private void Awake()
        {
            if (Instance != null)
            {
                IsCameraReady = false;
                Destroy(gameObject);
            }
            else
            {
                Instance = this;
            }
        }

        public void SetPlayerCameraPosition(float3 position, float deltaTime)
        {
            m_PlayerCameraTarget.position = math.lerp(m_PlayerCameraTarget.position, position, deltaTime * m_TargetFollowDamping);
        }

        public void SetPlayerCameraRotation(quaternion rotation, float deltaTime)
        {
            m_PlayerCameraTarget.rotation =
                math.slerp(m_PlayerCameraTarget.rotation, rotation, deltaTime * m_TargetFollowDamping);
        }
        
        public void Reset()
        {
            IsCameraReady = false;
            m_AutopilotCamera.gameObject.SetActive(false);
        }

        public void PlaceCamera(float3 position)
        {
            m_PlayerCameraTarget.position = position;
            IsCameraReady = true;
        }
    }
}
```

## Phase Two

Alright, so we've created three pieces of code now: 1) the PlayerCameraTarget component that will position and rotation information that 2) the ISystem PlayerCameraTargetUpdated will search for and then pass on to 3) the Hybrid Camera Manager (HCM) singleton that exposes two key functions: SetPlayerCameraPosition and SetPlayerCameraRotation. Those functions, when called via the HCM singleton, will update the transform of a camera that is tethered to the player in question.

The next step is to make sure that there is actual position and rotation information contained in the PlayerCameraTarget component. We'll get this information into the component via a script called Sys_PreparePlayerCameraTarget. I'm going to use the version from the Megacity sample with minimal changes (just changing a few variable names to fit my conventions):

```
using Unity.Burst;
using Unity.Entities;
using Unity.Transforms;

namespace Unity.Megacity.CameraManagement
{
    [BurstCompile]
    [UpdateBefore(typeof(TransformSystemGroup))]
    [UpdateBefore(typeof(PlayerCameraTargetUpdater))]
    [WorldSystemFilter(WorldSystemFilterFlags.LocalSimulation | WorldSystemFilterFlags.ClientSimulation)]
    public partial struct PreparePlayerCameraTarget : ISystem
    {
        [BurstCompile]
        partial struct UpdatePlayerCameraTargetDataJob : IJobEntity
        {
            [BurstCompile]
            public void Execute(ref PlayerCameraTarget playerCameraTarget, in LocalToWorld localToWorld)
            {
                playerCameraTarget.Position = localToWorld.Position;
                playerCameraTarget.Rotation = localToWorld.Rotation;
            }
        }
       
        [BurstCompile]
        public void OnCreate(ref SystemState state)
        {
            state.RequireForUpdate<PlayerCameraTarget>();
        }
       
        [BurstCompile]
        public void OnUpdate(ref SystemState state)
        {
            var updatePlayerTargetDataJob = new UpdatePlayerCameraTargetDataJob();
            state.Dependency = updatePlayerTargetDataJob.ScheduleParallel(state.Dependency);
            state.CompleteDependency();
        }
    }
}
```

## Conclusion

And that pretty much does it! The last two thing you have to do are make sure that you drag in the actual camera gameobject into the exposed field on the Hybrid Camera Manager and also ensure that you've added the relevant authoring script (Auth_PlayerCameraTarget, in my case) to your player character.
