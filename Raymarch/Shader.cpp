#include <fstream>
#include <iostream>
#include <sstream>
#include <string>

#include "Shader.h"
#include "macro.h"

Shader::Shader( const std::string & vert_filepath, const std::string & frag_filepath ) :
  m_VertFilePath( vert_filepath ), m_FragFilePath( frag_filepath ), m_RendererID( 0 )
{
  ShaderProgramSource source = ParseShader( vert_filepath, frag_filepath );
  m_RendererID               = CreateShader( source.VertexSource, source.FragmentSource );
}

Shader::~Shader()
{
  GLCall( glDeleteProgram( m_RendererID ) );
}

ShaderProgramSource Shader::ParseShader( const std::string & vert_filepath, const std::string & frag_filepath )
{
  std::ifstream vertstream( vert_filepath );
  std::ifstream fragstream( frag_filepath );

  std::string       line;
  std::stringstream ss[2];

  while( getline( vertstream, line ) )
  {
    ss[0] << line << '\n';
  }

  while( getline( fragstream, line ) )
  {
    ss[1] << line << '\n';
  }

  return { ss[0].str(), ss[1].str() };
}

unsigned int Shader::CompileShader( unsigned int type, const std::string & source )
{
  GLCall( unsigned int id = glCreateShader( type ) );
  const char * src = source.c_str();
  GLCall( glShaderSource( id, 1, &src, nullptr ) );
  GLCall( glCompileShader( id ) );

  int result;
  GLCall( glGetShaderiv( id, GL_COMPILE_STATUS, &result ) );
  if( result == GL_FALSE )
  {
    int length;
    GLCall( glGetShaderiv( id, GL_INFO_LOG_LENGTH, &length ) );
    char * message = (char *) alloca( length * sizeof( char ) );
    GLCall( glGetShaderInfoLog( id, length, &length, message ) );
    std::cout << "Failed to compile " << ( type == GL_VERTEX_SHADER ? "vertex" : "fragment" ) << " shader!" << std::endl;
    std::cout << message << std::endl;
    GLCall( glDeleteShader( id ) );
    return 0;
  }

  return id;
}

unsigned int Shader::CreateShader( const std::string & vertexShader, const std::string & fragmentShader )
{
  std::cout << vertexShader << std::endl;
  std::cout << fragmentShader << std::endl;
  GLCall( unsigned int program = glCreateProgram() );
  unsigned int vs = CompileShader( GL_VERTEX_SHADER, vertexShader );
  unsigned int fs = CompileShader( GL_FRAGMENT_SHADER, fragmentShader );

  GLCall( glAttachShader( program, vs ) );
  GLCall( glAttachShader( program, fs ) );
  GLCall( glLinkProgram( program ) );
  GLCall( glValidateProgram( program ) );

  GLCall( glDeleteShader( vs ) );
  GLCall( glDeleteShader( fs ) );

  return program;
}

void Shader::Bind() const
{
  GLCall( glUseProgram( m_RendererID ) );
}

void Shader::Unbind() const
{
  GLCall( glUseProgram( 0 ) );
}

void Shader::SetUniform1i( const std::string & name, int value )
{
  GLCall( glUniform1i( GetUniformLocations( name ), value ) );
}

void Shader::SetUniform1f( const std::string & name, float value )
{
  GLCall( glUniform1f( GetUniformLocations( name ), value ) );
}

void Shader::SetUniformVec3f( const std::string & name, glm::vec3 const & vec )
{
  GLCall( glUniform3fv( GetUniformLocations( name ), 1, &vec[0] ) );
}

void Shader::SetUniform4f( const std::string & name, float v0, float v1, float v2, float v3 )
{
  GLCall( glUniform4f( GetUniformLocations( name ), v0, v1, v2, v3 ) );
}

void Shader::SetUniformMat4f( const std::string & name, const glm::mat4 & matrix )
{
  GLCall( glUniformMatrix4fv( GetUniformLocations( name ), 1, GL_FALSE, &matrix[0][0] ) );
}

int Shader::GetUniformLocations( const std::string & name )
{
  if( m_UniformLocationCache.find( name ) != m_UniformLocationCache.end() )
    return m_UniformLocationCache[name];

  GLCall( int location = glGetUniformLocation( m_RendererID, name.c_str() ) );
  if( location == -1 )
    std::cout << "Warning: uniform '" << name << "' doesn't exist!" << std::endl;

  m_UniformLocationCache[name] = location;
  return location;
}
