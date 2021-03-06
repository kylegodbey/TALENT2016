#include <iostream>	// cout cin
#include <stdio.h>	// sprintf
#include <string>	// strings
#include <fstream>	// input/output files
#include <sstream>	// ...
#include <iomanip>	// setprecision()
#include <stdlib.h>	// abs
#include <math.h>	// sin
#include <vector>	// vectors
#include <algorithm>	// min_element
#include <functional>	// 
#include <numeric>	// accumulate
#include "spherical.h"	// header file

using namespace std;	// no need to put std:: before any cout, etc.


// Main code
int main()
{
	// Open input file
	string line;
	ifstream ipFile;
	ipFile.open("input.dat");

/*	for(int i=0; i<wBox/h; i++)
	{
		totPot.push_back(0.0);
		totProton.push_back(0.0);
		totNeutron.push_back(0.0);
	}
*/


	// Read in variables from file and store in vecot unless line is commented (starting with '#')
	while( getline( ipFile, line) )
	{
		if( line[0] != '#' )
		{
			istringstream iss(line);
			while(iss >> var)
			{
				variable.push_back(var);
			}
		}
	}

	// Set variables equal to those read in from input file
	//    selecctFunc = variable.at(0);	// Do not need, inherited from 1D code!
	    wBox = variable.at(1);	// Box width  [fm]
	   wWell = variable.at(2);	// Well width [fm] (don't use yet)
	       h = variable.at(3);	// Mesh width [fm]
	      V0 = variable.at(4);	// Well depth [MeV] (don't use yet)
	    eMin = variable.at(5);	// Min limit  [MeV]
	    eMax = variable.at(6);	// Max limit  [MeV]
	   eStep = variable.at(7);	// Step between different energies in brute force approach, needs getting rid of

	 wfStep1 = 0;			// First value for wavefunction, always set to 0
	 wfStep2 = variable.at(8);	// Second step along wavefunction
	 convEng = variable.at(9);	// Energy condition for convergence

	 nProton = variable.at(10);	// no. of protons for calculating Woods-Saxon
	nNeutron = variable.at(11);	// no. of neutrons for calculating Woods-Saxon

	vector<double> wf_val;		// Vector for wave function values

	int length = wBox/h;

	cout << "LENGTH: " << length << endl;

	vector<double> totPot(length,0.0);
	vector<double> totProton(length,0.0);
	vector<double> totNeutron(length,0.0);

	// Nice stuff for terminal output
	cout << "\n*************************************************************************" << endl;

	int nSteps = (eMax-eMin)/eStep;

//	totPot

	vector<double> wfTot;

	for(int isoSpin=0; isoSpin<2; isoSpin++)
	{
		if (isoSpin==0) cout << "*\tProtons \t\t\t\t\t\t\t*" << endl;
		else cout << "*\t\t\t\t\t\t\t\t\t*\n*\tNeutrons \t\t\t\t\t\t\t*" << endl;
		cout << "*\tEigen E [MeV]\tOrbital\t\tFilename\t\t\t*" << endl;

//		vector<double> pot;
//		for(int i=0; i<wBox/h; i++) pot.push_back(V(i*h+h,isoSpin,0,0));

		for(int L=0; L<8; L++) // Loop up to L=7 ( i.e. j_15/2) orbitals
		{
			int orbCheck;
			if(L==0) orbCheck =1;
			else orbCheck=2;
			for(int spin=0; spin<orbCheck; spin++)
			{
				eMin = variable.at(5);
				double Spin;
				if(spin==0) Spin = -0.5;
				else Spin = 0.5;

				int n = 1;

				// Loop for the calculation
				for(int jj=0; jj<nSteps; jj++) // (eMax+eMin)
				{
		
					wf_val.push_back(wfStep1);	// Initiate step 0 and step 1 WF values, if don't do this will not get past first calc.
					wf_val.push_back(wfStep2);	// NOTE: amplitude of calculated wavefunctions are arbitrary but defined by magnitude of
									//	 of this step, this is important when defining if calc. has converged.

					// Loop for calculating wavefunction values across the mesh, using the Numerov algorithm
					for(int i=0; i<wBox/h; i++)
					{
						wf_val.push_back(numerovAlgorithm(eMin, wf_val.at(i+1), wf_val.at(i), i*h, isoSpin, L, spin));
					}

					// Assign value to wfLast
					wfLast = wf_val.at(-1+wf_val.size());

					// This is where will converge the calculation
					// Need if jj>0 condition otherwise will have no previous value for wavefunction
					if(jj>0)
					{
						wfTmp = wf_val.at(-1+wf_val.size());

						// Check if there is a change in sign of wavefunction values at the limit of the box for
						// the most recent two different energies (wfPrev/wfLast negative if this is the case)
						if(wfPrev/wfLast < 0)
						{
							double eigenEng;	// initiate variable for energy eigenvalue

							// Check whether wavefunction at limit has pos. or neg. gradient at limit of box,
							// then calls the convergence function to calculate an energy eigenvalue
							if(wfPrev<wfLast)
							{
									eigenEng = converge(eMin-eStep,eMin,wfPrev,wfLast,isoSpin,L,spin);
							}
							else
							{
									eigenEng = converge(eMin,eMin-eStep,wfLast,wfPrev,isoSpin,L,spin);
							}
		
							// Clear previous wafefunction vector and initiate first two steps
							wf_val.clear();
							wf_val.push_back(wfStep1);
							wf_val.push_back(wfStep2);

							// Calculate eigenfunction using Numerov
							for(int i=0; i<wBox/h; i++) wf_val.push_back(numerovAlgorithm(eigenEng, wf_val.at(i+1), wf_val.at(i), i*h, isoSpin, L, spin));

							// Calculate normalisation factor
							normFac = normalise(eigenEng, isoSpin, L, spin);

							double j=Spin+L;

							char orbital[16];
							if(L==0) sprintf(orbital,"%is_%1.0f.2",n,fabs(2*j));
							if(L==1) sprintf(orbital,"%ip_%1.0f.2",n,2*j);
							if(L==2) sprintf(orbital,"%id_%1.0f.2",n,2*j);
							if(L==3) sprintf(orbital,"%if_%1.0f.2",n,2*j);
							if(L==4) sprintf(orbital,"%ig_%1.0f.2",n,2*j);
							if(L==5) sprintf(orbital,"%ih_%1.0f.2",n,2*j);
							if(L==6) sprintf(orbital,"%ii_%1.0f.2",n,2*j);
							if(L==7) sprintf(orbital,"%ij_%1.0f.2",n,2*j);

							// Write results to file with filename including energy eigenvalue
							char filename[512], eigEng[512];

							if(isoSpin==0) sprintf(filename,"results/proton_%s_%1.4f.dat",orbital,eigenEng);
							else sprintf(filename,"results/neutron_%s_%1.4f.dat",orbital,eigenEng);
							sprintf(eigEng,"%1.4f",eigenEng);

							ofstream opFile;
							opFile.open(filename);
							for(int k=0; k<wBox/h; k++) opFile << h*k << "\t" << sqrt(normFac)*wf_val.at(k) << "\t" << V(k*h, isoSpin, L, spin) << "\t" << woodsSaxon(k*h) << "\t" << centrifugal(k*h,L) << "\t" << spinOrbit(k*h,L,0.5) << "\t" << coulomb(k*h) << endl;
							opFile.close();

							// Output energy eigenvalue and the name of the file results are saved to
							cout << "*\t " << setprecision(10) << eigEng << "\t" << orbital << "\t\t" << filename << "\t*"  << endl;
							n++;

                            
							vector<double> density(length,0.0);

							for(int ii=0;ii<length;++ii)
							{
								wf_val[ii] *= sqrt(normFac);
								density[ii] = (2*j + 1)/(4*M_PI*pow(ii*h,2)) * pow(wf_val[ii],2);
								totPot[ii] += density[ii];

								if(isoSpin == 0)
								{
								    totProton[ii] += density[ii];
								}
								else
								{
								    totNeutron[ii] += density[ii];
								}
							}

						}
					}

					// Store the last value of the Numerov calculation 
					// so as to check whether change in sign in next iteration
					wfPrev = wfTmp;

					wf_val.clear(); // clear wf_val vector for next calculation with different trial energy
					eMin += eStep;	// increase energy.....will get rid of this
		
				}// Close loop over Energy mesh
				wfTmp =0;
				wfPrev=0;
			}	 // Close loop over +/- 1/2 spin
		}		 // Close looping over L values
	}			 // Close looping over isospin

	cout << "*************************************************************************\n" << endl;	// nice stuff for terminal output

	ofstream opFile;
	opFile.open("densities.dat");
	for(int i=0; i<wBox/h; i++) opFile << h*i << "\t" << totPot.at(i) << "\t" << totProton.at(i) << "\t" << totNeutron.at(i) << endl;
	opFile.close();

	cout << "Total nucleons: " << totalMatterDensity(totPot) << endl;
	cout << "Total protons: " << totalMatterDensity(totProton) << endl;
	cout << "Total neutrons: " << totalMatterDensity(totNeutron) << "\n" << endl;
}


// Numerov algorithm function.
//
// INPUT ARGUMENTS:
//     E = trial energy
//   f_x = Wavefunction value from previous step ( f(x)   from TALENT school notes)
// f_x_h = Wavefunction value from two steps ago ( f(x-h) from TALENT scrool notes)
double numerovAlgorithm(double E, double f_x, double f_x_h, double r, int isoSpin, int L, int spin)
{
	double a[3];		// Array for Numerov coefficients
	double Vr = (E-V(r+h, isoSpin, L, spin)) / hm_fac;	// Numerov potential

	a[0] = 2. * (1. - 5./12. * Vr * h * h);	// Coeff. for f(x)
	a[1] = 1. * (1. + 1./12. * Vr * h * h);	// Coeff. for f(x-h)
	a[2] = 1. * (1. + 1./12. * Vr * h * h);	// Coeff. for f(x+h)

	double nuWF = ((a[0] * f_x) - (a[1] * f_x_h)) / a[2]; // Calculate wavefunction value

	return nuWF;	// Return nuWF value when function called
}

// Function to converge on energy eigenvalue
//
// INPUT ARGUMENTS:
//  eLo = the energy of the step with the lowest wavefunction value
//  eHi = the energy of the step with the highest wavefunction value
// wfLo = lower wavefunction value of the two energy steps
// wfHi = higher wavefunction value of the two energy steps
double converge(double eLo, double eHi, double wfLo, double wfHi, int isoSpin, int L, int spin)
{
	// Initiate variables that will be used to decide convergence
	long double trialE = (eHi+eLo)/2;
	vector<long double> wf_val;
	long double wfBarr=0, wfEnd = 10;

	long double diffE=eStep;
	// While condition to carry on bisection convergence energy difference between
	// trial energy and previous energies is small enough
	while (fabs(wfEnd)>1e-5 && diffE>1e-6)
	{
		trialE = (eHi+eLo)/2;		// Trial energy based on average of two previous energies
		wf_val.push_back(wfStep1);	// Initiate Step 0 wavefunction value
		wf_val.push_back(wfStep2);	// Initiate Step 1 wavefunction value

		// Loop for calculating wavefunction values across the mesh, using the Numerov algorithm
		for(int i=0; i<wBox/h; i++)
		{
			wf_val.push_back(numerovAlgorithm(trialE, wf_val.at(i+1), wf_val.at(i), i*h, isoSpin, L, spin));
		}

		// Work out which wavefunction is......I think this is where the convergence function is messing up.
		if ( wf_val.at(-1+wf_val.size()) > 0)
		{
			 eHi = trialE;
			wfHi = wf_val.at(-1+wf_val.size());
		}
		else
		{
			 eLo = trialE;
			wfLo = wf_val.at(-1+wf_val.size());
		}
		wfEnd = wf_val.at(-1+wf_val.size());

		wfBarr = wf_val.at((wBox+wWell)/(2*h));

		wf_val.clear();	// clear wavefunction vector
		diffE = fabs(eHi-eLo);
	}

	if ( wfBarr/wfLo < 0 ) return eLo;
	else return eHi;
}

// Find factor for normalising wavefunction
double normalise(double eigenEng, int isoSpin, int L, int spin)
{
	vector<double> wfWork;
	wfWork.push_back(wfStep1);
	wfWork.push_back(wfStep2);

	double sum = 0;

	for(int i=0; i<wBox/h; i++) wfWork.push_back(numerovAlgorithm(eigenEng, wfWork.at(i+1), wfWork.at(i), i*h, isoSpin, L, spin));
	for(int i=0; i<(wBox/h)-1; i++) sum += h*pow(wfWork.at(i),2);

	double normFac = 1/sum;
	wfWork.clear();

	return normFac;
}

// Total potential
double V(double r, int isoSpin, int L, int spin)
{
	if (isoSpin == 0)
		return woodsSaxon(r) + centrifugal(r,L) + spinOrbit(r,L,spin) + coulomb(r);
	else
		return woodsSaxon(r) + centrifugal(r,L) + spinOrbit(r,L,spin);
}

// Woods-Saxon potential
double woodsSaxon(double r)
{
	double WS;
	double         A = nProton + nNeutron;
	double      R = r0 * pow(A,1./3);
	double coeffV = -51 + 33*((nNeutron-nProton)/A);

	WS = coeffV * (1 / ( 1 + exp( (r-R)/a0 )));

	return WS;
}

// Spin-orbit contribution
double spinOrbit(double r, int l, double spin)
{
	double s;
	if(l==0) return 0;
	else
	{
		if(spin==0) s = -0.5;
		else        s = 0.5;
		double    Vso = 0;
		int         A = nProton + nNeutron;
		double      R = r0 * pow(A,1./3);
		double      j = l+s;
		double   V_ls = Vls * 0.5 * ( j*(j+1) - l*(l+1) - 3./4 );

		Vso = V_ls * r0 * r0 * (-1/r) * ( (exp((r+R)/a0)) / (a0*pow((exp(R/a0)+exp(r/a0)),2)) );

//		Vso = V_ls * r0 * r0 * (-1/r) * ( (exp((r-R)/a0)) / (a0*pow((1+exp((r-R)/a0)),2)) );

		return Vso;
	}
}

// Centrifugal term
double centrifugal(double r, double l)
{
	double Vc = (hm_fac*l*(l+1)) / (r*r);
	return Vc;
}

// Coulomb potential
double coulomb(double r)
{
	double V_c;
	double Rp = r0 * pow(nProton,1./3);
	if(r<=Rp) V_c = (nProton * q * q / (2*Rp)) * (3 - pow(r/Rp,2));
	else V_c = nProton * q * q / r;

	return V_c;
}

double totalMatterDensity(vector<double> density)
{
	// Integrate total radial density 'density' to calculate A
	double A = 0.0;

	for(int i=1;i<density.size();++i)
	{
		A += density.at(i);
	}

	return A;
}
