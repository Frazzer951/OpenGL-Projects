#pragma once

#include "IndexBuffer.h"
#include "Renderer.h"
#include "Shader.h"
#include "Test.h"
#include "Texture.h"
#include "VertexArray.h"
#include "VertexBuffer.h"
#include "VertexBufferLayout.h"

#include "glm/glm.hpp"
#include "glm/gtc/matrix_transform.hpp"

namespace test
{
  class TestQuadRender : public Test
  {
  public:
    TestQuadRender();
    ~TestQuadRender();

    virtual void OnUpdate( float deltaTime ) override;
    virtual void OnRender() override;
    virtual void OnImGuiRender() override;

  private:
    float              m_Positions[16];
    unsigned int       m_Indices[6];
    unsigned int       m_Vao;
    VertexArray        m_Va;
    VertexBuffer       m_Vb;
    VertexBufferLayout m_Layout;
    IndexBuffer        m_Ib;
    glm::mat4          m_Proj;
    glm::mat4          m_View;
    Shader             m_Shader;
    Texture            m_Texture;
    Renderer           m_Renderer;
    glm::vec3          m_Translation;
  };
}    // namespace test