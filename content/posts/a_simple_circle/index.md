---
title: A Simple Circle
description: A short tutorial on making drawing a circle using bevy.
date: "2024-02-06T13:43:40"
draft: false 
tags: 
---

# Your First Bevy Circle

After one mangled attempt to do something far more grand, I've decided to pare things down and go after some easy prey: drawing a circle. *Audience gasps*. Do I dare attempt such a feat? Yes, yes I do -- and I'm going to make it even easier: I'm going to use of [some of the sample code contained on the Bevy website](https://bevyengine.org/examples/2D%20Rendering/2d-shapes/).

Really, a better name for this post would've been 'Starting Your First Bevy Project' or something like that, but we've already come this far so lets keep the ball rolling.

# Your First Bevy Project

Perhaps this isn't your first Bevy project, but I figured I would spend a quick second detailing how to do that before moving ahead. I highly recommend that you make use of cargo's built-in 'new' command that allows for the automatic generation of a new project:

Navigate to the folder you want to create your project and and then from the command line type:

```
cargo new project_name
```

As mentioned above, this line of command will cause cargo (Bevy's package (crate) manager) to automatically create all the base files necessary to get a project off the ground. Inside your created project directory, you should now see a cargo.toml file, which we'll touch on in just a second, and a folder named 'src' that contains your main.rs (that's where we'll be writing some code).

Quickly though, the cargo.toml file is your project's configuration file. If you look inside you should see something like this:

```
[package]
name = "rpg"
version = "0.1.0"
edition = "2021"

# See more keys and their definitions at https://doc.rust-lang.org/cargo/reference/manifest.html

[dependencies]
bevy = "0.12.1"
```

Nothing too fancy: a name, version, and edition year followed by a list of dependencies. One thing to note is that I didn't manually add that listing for Bevy to my cargo.toml file. Cargo did that for me when I wrote the following command:

```
cargo add bevy
```

Make sure you're within your project's main directory, but it should be as easy as that. Your cargo.toml file should now include a reference to bevy under the '[dependencies]'. If it didn't add it there for whatever reason, you should be able to add it manually and on your next recompile it should be listed.

## It's Circle Drawin' Time

Buckle up, because things are about to get wild. A fresh new piece of geometry is about to enter the world. Open up your main.rs (located in your 'src' folder) and let's with a few simple lines:

```
use bevy::{prelude::*, sprite::MaterialMesh2dBundle};

fn main()
{
    App::new()
        .add_plugins(DefaultPlugins)
        .add_systems(Startup, setup)
        .run();
}
```

The first line tells the compiler that we're going to be using the bevy package in this script as well as the MaterialMesh2dBundle from Bevy's sprite package. Note: Bundles are pretty cool -- they're pretty much just built-in templates that you can use to easily spawn various entities.

The next line is declare our main function which contains an App::new() declaration with chained calls to add_plugins and add_systems. The add_plugins(DefaultPlugins) call provides essential featueres for game creation within the Bevy framework. The add_systems call contains two parameters: the first, Startup, dictates when the second parameter, 'setup', should be run; in this case, the setup function, which we will see right away, will be run at...you guessed: during Startup.

Without further ado, the setup function (immediately follows fn main()):

```
fn setup(
    mut commands: Commands,
    mut meshes: ResMut<Assets<Mesh>>,
    mut materials: ResMut<Assets<ColorMaterial>>
){
    commands.spawn(Camera2dBundle::default());

    commands.spawn(MaterialMesh2dBundle {
        mesh: meshes.add(shape::Circle::new(50.).into()).into(),
        material: materials.add(ColorMaterial::from(Color::PURPLE)),
        transform: Transform::from_translation(Vec3::new(-150., 0., 0.)),
        ..default()
    });
}
```

There's a lot going on here! The setup function takes three parameters:

1) commands: Commands -- As you can see from a line further down (commands.spawn), the commands argument is used to make things happen in Bevy world. You'll see commands used a lot in Bevy code because they do all of the heavy lifting: creating and destroying entities and components, and modifying component data. Bevy also automatically schedule these commands to run at the appropriate time.

2) meshes: ResMut<Assets<Mesh>> -- There's a few things going on here that are worth noting. First, we have a 'mesh' type that's being turned into an asset and then a global, mutable resource. In other words, the mesh in question is being loaded by Bevy's asset loader and turned into an Assets<Mesh> and then it's being made into a global resource through the ResMut<> wrapper that allows various systems (including this one) to make use of it in their contained code.

3) materials: ResMut<Assets<ColorMaterial> -- Same as above, but this time a 'ColorMaterial' resource is being created instead of a 'Mesh'.

Well, that was already quite a bit! But we just have two 'commands.spawn' calls left.

The first:

```
  commands.spawn(Camera2dBundle::default());
```

Here's just a taste of Commands functionality. It's allowing us to spawn an entire 2D camera bundle in order for us to look at the circle that we're eventually going to draw (next paragraph!).

```
commands.spawn(MaterialMesh2dBundle {
        mesh: meshes.add(shape::Circle::new(50.).into()).into(),
        material: materials.add(ColorMaterial::from(Color::PURPLE)),
        transform: Transform::from_translation(Vec3::new(-150., 0., 0.)),
        ..default()
    });
```

And here it is, the final function call. As arguments, commands.spawn is passing in the MaterialMesh2dBundle that we saw from earlier, which itself is composed of a mesh (a shape), material (color), and a transform (position, rotation, scale).

1) Mesh: we're passing in your meshes argument (remember ResMut<Assets<Mesh>>) and calling the .add function. Inside this function we're using one of Bevy's default shapes (shape::Circle) and making a 'new' one with a radius of 50. The double .into() calls leverage Rust's built-in type inferencing to make the shape compatabile with its storage in ResMut<Assets<Mesh>>.

2) Material: once again, we're passing in an argument we saw above. This time it's our materials argument (ResMut<Assets<ColorMaterial>>). Same as with the .add call above, we're leveraging Rust's provided plugins to create a new ColorMaterial that's of the color purple. 

3) Transform: this one is different than the last two, as we didn't pass in any arguments that will go into this line. Instead, we're tapping into Bevy's Transform framework to create a new transform from a translation that will be supplied by a Vec3 (Vector3): Vec3::new(-150., 0., 0.)).

*And that's it!* There's nothing more to it, save for running the program and seeing the output:

```
cargo run
```

Type that command into your IDE's terminal, or manually in the command line. You should see something like this:

![A circle!](/first_circle.png)

Pretty cool, right? Obviously, it doesn't do much yet, but hopefully we can squeeze a bit more dynamism out of Bevy in future delvings. 
