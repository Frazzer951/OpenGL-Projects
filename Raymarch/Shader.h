#pragma once

#include <string>
#include <unordered_map>

#include "glm/glm.hpp"
#include "glm/gtc/matrix_transform.hpp"

struct ShaderProgramSource
{
  std::string VertexSource;
  std::string FragmentSource;
};

class Shader
{
private:
  std::string                          m_VertFilePath;
  std::string                          m_FragFilePath;
  unsigned int                         m_RendererID;
  std::unordered_map<std::string, int> m_UniformLocationCache;

public:
  Shader( const std::string & vert_filepath, const std::string & frag_filepath );
  ~Shader();

  void Bind() const;
  void Unbind() const;

  // Set Uniforms
  void SetUniform1i( const std::string & name, int value );
  void SetUniform1f( const std::string & name, float value );
  void SetUniformVec3f( const std::string & name, glm::vec3 const & vec );
  void SetUniform4f( const std::string & name, float v0, float v1, float v2, float v3 );
  void SetUniformMat4f( const std::string & name, const glm::mat4 & matrix );

private:
  ShaderProgramSource ParseShader( const std::string & vert_filepath, const std::string & frag_filepath );
  unsigned int        CompileShader( unsigned int type, const std::string & source );
  unsigned int        CreateShader( const std::string & vertexShader, const std::string & fragmentShader );
  int                 GetUniformLocations( const std::string & name );
};
