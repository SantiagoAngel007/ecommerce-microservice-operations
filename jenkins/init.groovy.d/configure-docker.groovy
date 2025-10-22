#!groovy
import jenkins.model.*
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.domains.Domain
import com.cloudbees.plugins.credentials.impl.*
import org.jenkinsci.plugins.docker.commons.credentials.*

def instance = Jenkins.getInstance()
def domain = Domain.global()
def store = SystemCredentialsProvider.getInstance().getStore()

// Las credenciales de Docker Hub se configurarÃ¡n manualmente
println("Jenkins configurado para usar Docker")
