#include <iostream>
#include <time.h>

#include "Shader.h"
#include "macro.h"

#include "GLFW/glfw3.h"
#include "glad/glad.h"
#include "glm/glm.hpp"

#define WIDTH  800
#define HEIGHT 600

using glm::vec3;

int main( void )
{
  GLFWwindow * window;

  /* Initialize the library */
  if( !glfwInit() )
    return -1;

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

  if( !gladLoadGLLoader( (GLADloadproc) glfwGetProcAddress ) )
    std::cout << "Error!" << std::endl;

  std::cout << glGetString( GL_VERSION ) << std::endl;
  {
    float positions[] = {
      -1.0f, -1.0f,    // 0
      +1.0f, -1.0f,    // 1
      +1.0f, +1.0f,    // 2
      -1.0f, +1.0f     // 3
    };

    unsigned int indices[] = {
      0, 1, 2,
      2, 3, 0
    };

    unsigned int vao;
    GLCall( glGenVertexArrays( 1, &vao ) );
    GLCall( glBindVertexArray( vao ) );

    unsigned int buffer;
    GLCall( glGenBuffers( 1, &buffer ) );
    GLCall( glBindBuffer( GL_ARRAY_BUFFER, buffer ) );
    GLCall( glBufferData( GL_ARRAY_BUFFER, 4 * 2 * sizeof( float ), positions, GL_STATIC_DRAW ) );

    GLCall( glEnableVertexAttribArray( 0 ) );
    GLCall( glVertexAttribPointer( 0, 2, GL_FLOAT, GL_FALSE, sizeof( float ) * 2, 0 ) );

    unsigned int ibo;
    GLCall( glGenBuffers( 1, &ibo ) );
    GLCall( glBindBuffer( GL_ELEMENT_ARRAY_BUFFER, ibo ) );
    GLCall( glBufferData( GL_ELEMENT_ARRAY_BUFFER, 6 * sizeof( unsigned int ), indices, GL_STATIC_DRAW ) );

    //Shader shader( "shaders/vert.glsl", "shaders/sierpinski2.glsl" );
    //Shader shader( "shaders/vert.glsl", "shaders/sierpinski.glsl" );
    //Shader shader( "shaders/vert.glsl", "shaders/mengerSponge.glsl" );
    //Shader shader( "shaders/vert.glsl", "shaders/raymarch.glsl" );
    //Shader shader( "shaders/vert.glsl", "shaders/unreal_intro_frag.glsl" );
    //Shader shader( "shaders/vert.glsl", "shaders/fire_ball_frag.glsl" );
    //Shader shader( "shaders/vert.glsl", "shaders/frag.glsl" );
    Shader shader( "shaders/vert.glsl", "shaders/mandelbrot.glsl" );

    GLCall( glBindVertexArray( 0 ) );
    GLCall( glUseProgram( 0 ) );
    GLCall( glBindBuffer( GL_ARRAY_BUFFER, 0 ) );
    GLCall( glBindBuffer( GL_ELEMENT_ARRAY_BUFFER, 0 ) );

    // Ensure we can capture the escape key being pressed below
    glfwSetInputMode( window, GLFW_STICKY_KEYS, GL_TRUE );
    glfwSetCursorPos( window, WIDTH / 2, HEIGHT / 2 );

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

      GLCall( glBindVertexArray( vao ) );
      GLCall( glBindBuffer( GL_ELEMENT_ARRAY_BUFFER, ibo ) );

      GLCall( glDrawElements( GL_TRIANGLES, 6, GL_UNSIGNED_INT, nullptr ) );

      glfwSwapBuffers( window );
      glfwPollEvents();
    }
  }

  glfwTerminate();
  return 0;
}