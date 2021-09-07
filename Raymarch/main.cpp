#include <iostream>
#include <time.h>

#include "Shader.h"
#include "macro.h"

#include "GL/glew.h"
#include "GLFW/glfw3.h"
#include "glm/glm.hpp"

#define WIDTH  800
#define HEIGHT 600

using glm::vec3;

int main( void )
{
  GLFWwindow * window;

  /* Initialize the library */
  if( !glfwInit() ) return -1;

  glfwWindowHint( GLFW_CONTEXT_VERSION_MAJOR, 3 );
  glfwWindowHint( GLFW_CONTEXT_VERSION_MINOR, 3 );
  glfwWindowHint( GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE );

  /* Create a windowed mode window and its OpenGL context */
  window = glfwCreateWindow( WIDTH, HEIGHT, "RayMarch", NULL, NULL );
  if( !window )
  {
    glfwTerminate();
    return -1;
  }

  /* Make the window's context current */
  glfwMakeContextCurrent( window );

  glfwSwapInterval( 1 );

  if( glewInit() != GLEW_OK ) std::cout << "Error!" << std::endl;

  std::cout << glGetString( GL_VERSION ) << std::endl;

  float positions[8] {
    -0.5f, -0.5f,    // 0
    +0.5f, -0.5f,    // 1
    +0.5f, +0.5f,    // 2
    -0.5f, +0.5f     // 3
  };

  unsigned int indices[] {
    0, 1, 2,
    2, 3, 0
  };

  unsigned int buffer;
  GLCall( glGenBuffers( 1, &buffer ) );
  GLCall( glBindBuffer( GL_ARRAY_BUFFER, buffer ) );
  GLCall( glBufferData( GL_ARRAY_BUFFER, 4 * 2 * sizeof( float ), positions, GL_STATIC_DRAW ) );

  GLCall( glEnableVertexAttribArray( 0 ) );
  GLCall( glVertexAttribPointer( 0, 2, GL_FLOAT, GL_FALSE, sizeof( float ) * 2, 0 ) );

  unsigned int ibo;
  GLCall( glGenBuffers( 1, &ibo ) );
  GLCall( glBindBuffer( GL_ELEMENT_ARRAY_BUFFER, ibo ) );
  GLCall( glBufferData( GL_ELEMENT_ARRAY_BUFFER, 2 * 3 * sizeof( unsigned int ), indices, GL_STATIC_DRAW ) );

  GLCall( glBindBuffer( GL_ARRAY_BUFFER, 0 ) );

  // Ensure we can capture the escape key being pressed below
  glfwSetInputMode( window, GLFW_STICKY_KEYS, GL_TRUE );
  glfwSetCursorPos( window, WIDTH / 2, HEIGHT / 2 );
  GLEW_ARB_debug_output;

  //Shader shader( "shaders/vert.glsl", "shaders/fire_ball_frag.glsl" );
  Shader shader( "shaders/vert.glsl", "shaders/frag.glsl" );

  vec3    iResolution = vec3( WIDTH, HEIGHT, 0 );
  clock_t start_time  = clock();
  clock_t curr_time;
  float   playtime_in_second = 0;

  while( glfwGetKey( window, GLFW_KEY_ESCAPE ) != GLFW_PRESS && !glfwWindowShouldClose( window ) )
  {
    GLCall( glClear( GL_COLOR_BUFFER_BIT ) );

    curr_time          = clock();
    playtime_in_second = ( curr_time - start_time ) * 1.0f / 1000.0f;

    shader.Bind();
    shader.SetUniformVec3f( "iResolution", iResolution );
    shader.SetUniform1f( "iTime", playtime_in_second );

    GLCall( glDrawElements( GL_TRIANGLES, 6, GL_UNSIGNED_INT, nullptr ) );

    glfwSwapBuffers( window );
    glfwPollEvents();
  }

  glfwTerminate();
  return 0;
}