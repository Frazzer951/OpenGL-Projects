#include "TestQuadRender.h"

#include "imgui/imgui.h"

namespace test
{
  TestQuadRender::TestQuadRender() :
    m_Positions {
      -50.0f, -50.0f, +0.0f, +0.0f,    // 0
      +50.0f, -50.0f, +1.0f, +0.0f,    // 1
      +50.0f, +50.0f, +1.0f, +1.0f,    // 2
      -50.0f, +50.0f, +0.0f, +1.0f     // 3
    },
    m_Indices {
      0, 1, 2,
      2, 3, 0
    },
    m_Vao( 0 ), m_Va(), m_Vb( m_Positions, 4 * 4 * sizeof( float ) ), m_Layout(),
    m_Ib( m_Indices, 6 ), m_Proj( glm::ortho( 0.0f, 960.0f, 0.0f, 540.0f, -1.0f, 1.0f ) ),
    m_View( glm::translate( glm::mat4( 1.0f ), glm::vec3( 0, 0, 0 ) ) ),
    m_Shader( "res/shaders/Basic.shader" ), m_Texture( "res/textures/ChernoLogo.png" ),
    m_Renderer(), m_Translation( 200, 200, 0 )
  {
    GLCall( glGenVertexArrays( 1, &m_Vao ) );
    GLCall( glBindVertexArray( m_Vao ) );

    m_Layout.Push<float>( 2 );
    m_Layout.Push<float>( 2 );
    m_Va.AddBuffer( m_Vb, m_Layout );

    m_Shader.Bind();
    m_Texture.Bind();
    m_Shader.SetUniform1i( "u_Texture", 0 );

    m_Va.Unbind();
    m_Vb.Unbind();
    m_Ib.Unbind();
    m_Shader.Unbind();
  }

  TestQuadRender::~TestQuadRender()
  {
  }

  void TestQuadRender::OnUpdate( float deltaTime )
  {
  }

  void TestQuadRender::OnRender()
  {
    m_Shader.Bind();

    glm::mat4 model = glm::translate( glm::mat4( 1.0f ), m_Translation );
    glm::mat4 mvp   = m_Proj * m_View * model;
    m_Shader.SetUniformMat4f( "u_MVP", mvp );

    m_Renderer.Draw( m_Va, m_Ib, m_Shader );
  }

  void TestQuadRender::OnImGuiRender()
  {
    ImGui::SliderFloat3( "Translation", &m_Translation.x, 0.0f, 960.0f );
  }

}    // namespace test