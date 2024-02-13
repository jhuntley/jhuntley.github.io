---
title: Exploring Bevy - Steps Towards a 2D RPG
description: 

date: "2024-02-12T13:43:40"
draft: true
tags: 
---

#Steps Towards a 2D RPG in Bevy

First things first: for those who don't know, Bevy is an open-source game engine that has been built from the ground up to support creating games using an ECS (Entity Component System) framework. It supports both 2D and 3D, but at the time of writing an editor has yet to be written that would allow for a more fluid development experience. For those (like me), who are used to working with a graphical interface in game development, this lack of editor support certainly poses a bit of a challenge...

But nevertheless I'm still curious to jump in! In what follows, I'll be attempting to bungle/frolick my way through setting up a top-down 2D RPG. I'll most likely be drawing upon a number of open source projects along the way, but right out of the gate I'll be looking at a fun little game called *Magus Parvus*[https://github.com/PraxTube/magus-parvus/]. I've looked over the source code a number of times in the past month to the point where I feel like I should be able to get something running on my own.

## First things first: creating the directory

As with any new project the first thing I'm going to do is setup a new directory. At first, I did this manually, just creating main.rs by hand, but then I remembered that cargo (Rust's package manager) has a built-in command called 'new' that allows for easy project generation, so I ended up using that. It worked pretty swell, giving me both cargo.toml file (where project dependencies are stored) and a 'src' folder containing a main.rs.

From there, I pilfered from the *Magus Parvus* source code, downloading all of the assets and the code contained in the author's main.rs. My plan is to try and use his source code as a foundation for doing my own explorings. My hunch (as the code compiles right now) is that I'll probably need to incorporate quite a bit of the original code to get things off the ground, but we will see. While I'm waiting, I'm also having fun practicing some beginner-level powershell magic...on about the fifth try I was finally able to get the files I wanted copied over! Something like progress!

## One thing to note

Before spearing forward (and while the project continues to compile...zzz), I figured it might be good to touch on the tech stack that this little projects employs. Here is what the cargo.toml files lists as the project's dependencies:

```
rand = "0.8.5"
chrono = "0.4.31"

bevy = "0.12.1"
bevy_screen_diagnostics = "0.4.0"
bevy_asset_loader = { version = "0.18.0", features = ["2d"] }
bevy_ecs_ldtk = { git = "https://github.com/PraxTube/bevy_ecs_ldtk.git", branch = "feat/bevy-0.12", features = ["atlas"]}
bevy_rapier2d = "0.23.0"
bevy_kira_audio = "0.18.0"
bevy_trickfilm = { git = "https://github.com/PraxTube/bevy_trickfilm", branch = "main" }
noisy_bevy = "0.5.0"
```

I'm guessing the rand and chrono crates (the name for packages in Rust) deal with random numbers and time, respectively. Bevy and bevy_screen_diagnostics are the bevy game engine and its debugging tools. Bevy_asset_loader is self explanatory. Bevy_ecs_ldtk is a crate that allows for the importing of maps from the 2D level builder LDTK. Rapier2D handles physics; kira, audio; trickfilm, animations; and lastly, noisy_bevy allows for a camera shake effect.

Not too much there, but a few things worth going over! 

## The First Build

Alright, so my first build of the project fell on its face. My previous celebration about using copy-item (cp) was apparently premature, as I managed to copy all of the assets into the source directory instead of the root directory. Thankfully, Rust provided me with a helpful error message that guided me towards the light.

Side note: One thing I'm noticing right now is that build times seem to take a very long time. I don't know what to make of this yet, and I'm assuming that it's probably just related to me building the project from scratch, but I guess I'll have to wait and see.

### Another discovery

While waiting for the code to build, I ran across this post on Stack Overflow that pointed to a few lines of code to add to the cargo.toml file to speed up the build process:

```
# Enable a small amount of optimization in debug mode
[profile.dev]
opt-level = 1

# Enable high optimizations for dependencies (incl. Bevy), but not for our code:
[profile.dev.package."*"]
opt-level = 3
```

The funny thing is, these two snippets of code are already inside my cargo.toml file! To make use of them, the Stack Overflow post suggests using the following command:

```
cargo run --feature "bevy/dynamic_linking"
```

Apparently, this speeds the process up by making a .dll and then linking the created app to that .dll (rather then incorporating all of that code into the app itself). I don't think this is going to speed up my build woes (I'm not sure), but I'm definitely going to give this a shot once I can get everything running.

