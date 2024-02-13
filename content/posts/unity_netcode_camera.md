---
title: Netcode for Entities - Spawning Player Cameras 
description: A short post detailing how to spawn cameras for individual players in Unity using their Entity Component System and Netcode for Entities
date: "2024-02-11T13:43:40"
draft: false
tags: 
---

# Introduction

I originally wrote this post with the idea that it would provide a short tutorial on camera creation within the Unity Netcode for Entities (ECS) framework. Ideas, of course, are just that -- *ideas* -- and creating the cameras and getting them working turned out to be both a far larger (and in the end, far simpler) problem than I initially imagined. Part of the problem was that I was trying to wrap my head around both a new conceptual territory (network programming) and a new framework (Netcode for Entities), which made it difficult to pick out core concepts and to scaffold my learning in a way that felt scalable and structured.

Another challenge was that I'd already done a significant amount of coding before adding the multiplayer code into the game. Even though I waited for a few weeks to add the multiplayer code, I'd already created large segments of gameplay. With that said, I'm grateful that I didn't wait any longer and that I did jump in and add it when I did, because I know the territory could've become far more gnarly. 

*Gnarly?* you might ask. *What's so difficult about adding multiplayer code in at a later date*. My hunch is that there's countless youtube videos explaining this in great detail, but from my direct experience one of the major challenges was the emergence of *false negatives* -- that is, code this is actually working (at least a part of it), but gains the appearance of *not working* because of other scripts / systems medling with the presentation or the underlying logic.

In the case of the cameras, this looked like a system we use for detecting the camera facing direction giving the appearance that there weren't unique cameras in the scene. To flesh things out, I was trying to make it so that a unique camera would spawn for each player as they joined the game, but when I went to test the code, it appeared as if the camera *wasn't unique* because of the mouse facing system. It was a false negative, one that obscured the fact that the underlying camera creation code was indeed working.

I'll be the first to admit it: I probably should've clued into this sooner than I did, but at the same time I was testing multiple solutions and trying to wrap my head around a lot of concepts. It was really easy just to check the 'failed solution' box in my brain and move on to the next idea. There were other problems with that solution as well that I won't go into, but ultimatley it ended up working when we returned to it and gave it another shot (this time following the Megacity sample in using a Cinemachine).

I hestitate to label what follows a tutorial as it's very bare bones, but I'm going to keep it in any way just for the sake of completeness. One note: this tutorial was written before I encountered the challenges, and so if you detect a note of naive optimism you would not be mistaken. *I strongly suggest using the code that follows as a mere taking off point*. I offer a few more reflections in the conclusion.


# Leveraging Unity's Megacity Multiplayer Sample

After struggling to implement my own solution, I decided to dive into Unity's Megacity Multiplayer sample and see if there was anything in there that might be able to help me get the cameras running. It took me a little while to wrap my head around the codebase, but it turns out thay they were using a hybrid solution that was quite similar to what I had tried. The key difference, however, was that instead of trying to pass a singleton information about the players (my attempted solution), the unity developers let an ISystem paired with an IJobEntity pass information via a singleton -- the Hybrid Camera Manager.

# First Steps

The first step to get this rolling is to make sure there's actually a component available that the IJobEntity job mentioned above can find. I've gone ahead and named this component PlayerCameraTarget (following the sample), as it will store the current player data for the camera:

```
using Unity.Entities;
using Unity.Mathematics;
using Unity.NetCode;

namespace Unity.Megacity.CameraManagement
{
    /// <summary>
    /// Update the hybrid camera target with player position camera target in order for the virtual camera to follow it
    /// </summary>
    [GhostComponent(PrefabType = GhostPrefabType.PredictedClient)]
    public struct PlayerCameraTarget : IComponentData
    {
        public float3 PositionOffset;
        public float3 Position;
        public quaternion Rotation;
    }
}
```

Note the GhostComponent attribute attached to the component. This is key. In my understanding, this attribute specifies that the client should both simulate and predict the the behaviour of the entity attached to this component. More specifically, it tells the server and client that this component will be subject to regular updates and that the data predicated by the client (to help with smoothing) might need to be overwritten by the server data if there's a contradiction. 

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

## Updated Conclusion

Well, after I wrote the lines above, I spent an ungodly number of hours trying to get the code to actually work, as hinted at in the introduction to this piece. Thankfully, my brother (the co-developer and artist-extraodinaire on this project) rolled up his sleeves and did his own implementation of the Unity Megacity code. Thankfully, thankfully, it worked. From our brief discussion, it appeared that using a virtual Cinemachine (just like the Unity project) alleviated some of the issues. He also picked up on the bug with the mouse facing system that was distorting the camera view.

What else to say? For myself, I think moving forward I'm going to spend more time making sure I accurately and fully understand the problem at hand before casting aside potential solutions. I'm also going to be implementing multiplayer code from the start in any future projects -- it isn't the most appealing way to start a project, but I'd rather that than a day of headaches.

I hope your camera implementation journeys go far better than mine!
