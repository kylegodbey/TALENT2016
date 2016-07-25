#include "Nucleus.h"

Nucleus::Nucleus (Basis & basis, Interaction & _inter, int nbNeut, int nbProt) 
    : System("Nucleus", basis, arma::ivec {nbNeut,nbProt}, std::vector<std::string> {"Neutrons","Protons"}, _inter)
{
}

Nucleus::~Nucleus()
{
}

void Nucleus::calcH0(int type)
{
  (void)type;
}

void Nucleus::calcH()
{
}
